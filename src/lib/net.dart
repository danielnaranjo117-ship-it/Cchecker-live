import 'dart:convert';
import 'dart:io';

import 'core.dart';

class Doh {
  static final Map<String, String> _cache = {};

  static Future<String?> resolve(String host) async {
    if (_cache.containsKey(host)) return _cache[host];
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) return host;

    for (final base in dohUrls) {
      try {
        final hc = HttpClient()..connectionTimeout = const Duration(seconds: 6);
        final req = await hc.getUrl(Uri.parse('$base?name=$host&type=A'));
        req.headers.set('accept', 'application/dns-json');
        final res = await req.close().timeout(const Duration(seconds: 6));
        final txt = await res.transform(utf8.decoder).join();
        hc.close();
        if (res.statusCode != 200) continue;
        final map = jsonDecode(txt) as Map<String, dynamic>;
        final ans = map['Answer'];
        if (ans is List) {
          for (final a in ans) {
            if (a is Map && (a['type'] == 1)) {
              final ip = a['data'].toString();
              _cache[host] = ip;
              return ip;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}

Future<ConnectionTask<Socket>> dohFactory(
  Uri uri,
  String? proxyHost,
  int? proxyPort,
  int timeoutSec,
) {
  final fut = _connectVia(uri.host, uri.port, timeoutSec);
  return ConnectionTask.fromSocket(fut, () {});
}

Future<Socket> _connectVia(String host, int port, int timeoutSec) async {
  final ip = await Doh.resolve(host);
  return Socket.connect(ip ?? host, port, timeout: Duration(seconds: timeoutSec));
}

class NetSense {
  NetSense._();
  static final NetSense i = NetSense._();
  int backoff(int attempt) {
    final base = 300 * attempt;
    return base > 3000 ? 3000 : base;
  }
}
