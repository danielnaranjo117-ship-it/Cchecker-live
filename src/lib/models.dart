import 'core.dart';

enum CheckStatus {
  unchecked,
  checking,
  live,
  noFunds,
  need3ds,
  cvcFail,
  avsFail,
  restricted,
  unknown,
  dead,
}

extension CheckStatusX on CheckStatus {
  String get label => switch (this) {
        CheckStatus.unchecked => 'sin comprobar',
        CheckStatus.checking => 'comprobando',
        CheckStatus.live => 'viva',
        CheckStatus.noFunds => 'sin fondos',
        CheckStatus.need3ds => 'pide 3ds',
        CheckStatus.cvcFail => 'cvv malo',
        CheckStatus.avsFail => 'zip malo',
        CheckStatus.restricted => 'restringida',
        CheckStatus.unknown => 'incierta',
        CheckStatus.dead => 'muerta',
      };

  String get tag => switch (this) {
        CheckStatus.live => 'LIVE',
        CheckStatus.noFunds => 'FUNDS',
        CheckStatus.need3ds => '3DS',
        CheckStatus.cvcFail => 'CVC',
        CheckStatus.avsFail => 'AVS',
        CheckStatus.restricted => 'REST',
        CheckStatus.dead => 'DEAD',
        CheckStatus.checking => '...',
        CheckStatus.unknown => '?',
        CheckStatus.unchecked => '-',
      };

  bool get cobrable =>
      this == CheckStatus.live ||
      this == CheckStatus.noFunds ||
      this == CheckStatus.need3ds ||
      this == CheckStatus.cvcFail ||
      this == CheckStatus.avsFail ||
      this == CheckStatus.restricted;

  int get rank => switch (this) {
        CheckStatus.live => 0,
        CheckStatus.noFunds => 1,
        CheckStatus.need3ds => 2,
        CheckStatus.cvcFail => 3,
        CheckStatus.avsFail => 4,
        CheckStatus.restricted => 5,
        CheckStatus.unknown => 9,
        CheckStatus.dead => 10,
        CheckStatus.checking => 11,
        CheckStatus.unchecked => 12,
      };
}

class CreditCard {
  CreditCard({
    required this.id,
    required this.pan,
    required this.expMonth,
    required this.expYear,
    this.cvv = '',
    this.brand = '',
    this.bin = '',
    this.bank = '',
    this.country = '',
    this.level = '',
    this.kind = '',
    this.status = CheckStatus.unchecked,
    this.message = '',
    this.gateway = '',
    this.latencyMs = 0,
    this.checkedAt,
  });

  final String id;
  final String pan;
  final int expMonth;
  final int expYear;
  final String cvv;
  final String brand;
  final String bin;
  final String bank;
  final String country;
  final String level;
  final String kind;
  final CheckStatus status;
  final String message;
  final String gateway;
  final int latencyMs;
  final DateTime? checkedAt;

  String get exp => '${pad2(expMonth)}/${pad2(expYear)}';
  String get key => '$pan|${pad2(expMonth)}|${pad2(expYear)}|$cvv';
  bool get expired => expiredCard(expMonth, expYear);

  CreditCard copyWith({
    CheckStatus? status,
    String? message,
    String? gateway,
    int? latencyMs,
    DateTime? checkedAt,
    String? bank,
    String? country,
    String? level,
    String? kind,
    String? brand,
  }) =>
      CreditCard(
        id: id,
        pan: pan,
        expMonth: expMonth,
        expYear: expYear,
        cvv: cvv,
        brand: brand ?? this.brand,
        bin: bin,
        bank: bank ?? this.bank,
        country: country ?? this.country,
        level: level ?? this.level,
        kind: kind ?? this.kind,
        status: status ?? this.status,
        message: message ?? this.message,
        gateway: gateway ?? this.gateway,
        latencyMs: latencyMs ?? this.latencyMs,
        checkedAt: checkedAt ?? this.checkedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pan': pan,
        'mm': expMonth,
        'yy': expYear,
        'cvv': cvv,
        'brand': brand,
        'bank': bank,
        'country': country,
        'level': level,
        'kind': kind,
        'st': status.name,
        'msg': message,
        'gw': gateway,
        'ms': latencyMs,
        'at': checkedAt?.toIso8601String(),
      };

  static CreditCard fromJson(Map<String, dynamic> j) {
    final pan = (j['pan'] ?? '').toString();
    return CreditCard(
      id: (j['id'] ?? newId()).toString(),
      pan: pan,
      expMonth: ((j['mm'] ?? 1) as num).toInt(),
      expYear: ((j['yy'] ?? 30) as num).toInt(),
      cvv: (j['cvv'] ?? '').toString(),
      brand: (j['brand'] ?? '').toString(),
      bin: pan.length >= 6 ? pan.substring(0, 6) : '',
      bank: (j['bank'] ?? '').toString(),
      country: (j['country'] ?? '').toString(),
      level: (j['level'] ?? '').toString(),
      kind: (j['kind'] ?? '').toString(),
      status: CheckStatus.values.firstWhere(
        (s) => s.name == j['st'],
        orElse: () => CheckStatus.unchecked,
      ),
      message: (j['msg'] ?? '').toString(),
      gateway: (j['gw'] ?? '').toString(),
      latencyMs: ((j['ms'] ?? 0) as num).toInt(),
      checkedAt: j['at'] == null ? null : DateTime.tryParse(j['at'].toString()),
    );
  }
}

enum ProxyKind { http, socks }

enum ProxyHealth { unknown, ok, down }

class ProxyNode {
  ProxyNode({
    required this.id,
    required this.host,
    required this.port,
    this.user = '',
    this.pass = '',
    this.kind = ProxyKind.http,
    this.health = ProxyHealth.unknown,
    this.latencyMs = 0,
  });

  final String id;
  final String host;
  final int port;
  final String user;
  final String pass;
  final ProxyKind kind;
  final ProxyHealth health;
  final int latencyMs;

  String get label => '$host:$port';

  ProxyNode copyWith({ProxyHealth? health, int? latencyMs}) => ProxyNode(
        id: id,
        host: host,
        port: port,
        user: user,
        pass: pass,
        kind: kind,
        health: health ?? this.health,
        latencyMs: latencyMs ?? this.latencyMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': host,
        'port': port,
        'u': user,
        'p': pass,
        'k': kind.name,
        'h': health.name,
        'ms': latencyMs,
      };

  static ProxyNode fromJson(Map<String, dynamic> j) => ProxyNode(
        id: (j['id'] ?? newId()).toString(),
        host: (j['host'] ?? '').toString(),
        port: ((j['port'] ?? 8080) as num).toInt(),
        user: (j['u'] ?? '').toString(),
        pass: (j['p'] ?? '').toString(),
        kind: ProxyKind.values.firstWhere(
          (k) => k.name == j['k'],
          orElse: () => ProxyKind.http,
        ),
        health: ProxyHealth.values.firstWhere(
          (h) => h.name == j['h'],
          orElse: () => ProxyHealth.unknown,
        ),
        latencyMs: ((j['ms'] ?? 0) as num).toInt(),
      );
}

class ImportResult {
  ImportResult({
    required this.cards,
    this.duplicates = 0,
    this.junk = 0,
    this.fixed = 0,
    this.expired = 0,
  });
  final List<CreditCard> cards;
  final int duplicates;
  final int junk;
  final int fixed;
  final int expired;
}

class Settings {
  const Settings({
    this.engine = 'stripe',
    this.stripeKey = stripePk,
    this.stripeSk = '',
    this.dorkillKey = '',
    this.retries = 1,
    this.useProxies = false,
    this.doh = true,
    this.concurrency = 6,
    this.timeoutSec = 20,
    this.probeUrl = defaultProbe,
    this.biometrics = false,
    this.autoLockMin = 5,
    this.enrich = true,
    this.binDbUrl = '',
  });

  final String engine;
  final String stripeKey;
  final String stripeSk;
  final String dorkillKey;
  final int retries;
  final bool useProxies;
  final bool doh;
  final int concurrency;
  final int timeoutSec;
  final String probeUrl;
  final bool biometrics;
  final int autoLockMin;
  final bool enrich;
  final String binDbUrl;

  bool get authOn => cleanSk.startsWith('sk_');
  String get cleanSk => stripeSk
      .trim()
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll(RegExp(r'\s'), '');
  String get mode =>
      authOn ? 'auth real' : (engine == 'both' ? 'cascada' : engine == 'dorkill' ? 'dorkill' : 'token');

  Settings copyWith({
    String? engine,
    String? stripeKey,
    String? stripeSk,
    String? dorkillKey,
    int? retries,
    bool? useProxies,
    bool? doh,
    int? concurrency,
    int? timeoutSec,
    String? probeUrl,
    bool? biometrics,
    int? autoLockMin,
    bool? enrich,
    String? binDbUrl,
  }) =>
      Settings(
        engine: engine ?? this.engine,
        stripeKey: stripeKey ?? this.stripeKey,
        stripeSk: stripeSk ?? this.stripeSk,
        dorkillKey: dorkillKey ?? this.dorkillKey,
        retries: retries ?? this.retries,
        useProxies: useProxies ?? this.useProxies,
        doh: doh ?? this.doh,
        concurrency: concurrency ?? this.concurrency,
        timeoutSec: timeoutSec ?? this.timeoutSec,
        probeUrl: probeUrl ?? this.probeUrl,
        biometrics: biometrics ?? this.biometrics,
        autoLockMin: autoLockMin ?? this.autoLockMin,
        enrich: enrich ?? this.enrich,
        binDbUrl: binDbUrl ?? this.binDbUrl,
      );

  Map<String, dynamic> toJson() => {
        'engine': engine,
        'pk': stripeKey,
        'ssk': stripeSk,
        'dk': dorkillKey,
        'retries': retries,
        'px': useProxies,
        'doh': doh,
        'conc': concurrency,
        'to': timeoutSec,
        'probe': probeUrl,
        'bio': biometrics,
        'lock': autoLockMin,
        'enrich': enrich,
        'binurl': binDbUrl,
      };

  static Settings fromJson(Map<String, dynamic> j) => Settings(
        engine: (j['engine'] ?? 'stripe').toString(),
        stripeKey: (j['pk'] ?? stripePk).toString(),
        stripeSk: (j['ssk'] ?? '').toString(),
        dorkillKey: (j['dk'] ?? '').toString(),
        retries: ((j['retries'] ?? 1) as num).toInt(),
        useProxies: j['px'] == true,
        doh: j['doh'] != false,
        concurrency: ((j['conc'] ?? 6) as num).toInt(),
        timeoutSec: ((j['to'] ?? 20) as num).toInt(),
        probeUrl: (j['probe'] ?? defaultProbe).toString(),
        biometrics: j['bio'] == true,
        autoLockMin: ((j['lock'] ?? 5) as num).toInt(),
        enrich: j['enrich'] != false,
        binDbUrl: (j['binurl'] ?? '').toString(),
      );
}
