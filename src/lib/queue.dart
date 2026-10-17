import 'checker.dart';
import 'models.dart';

Future<void> runMass({
  required List<CreditCard> cards,
  required Settings cfg,
  required List<ProxyNode> proxies,
  required void Function(CreditCard) onCard,
  required void Function(int done, int total) onProgress,
  required bool Function() stop,
}) async {
  if (cards.isEmpty) return;
  final engine = CheckEngine(cfg, proxies: proxies);
  var next = 0;
  var done = 0;
  final workers = cfg.concurrency < 1 ? 1 : (cfg.concurrency > 32 ? 32 : cfg.concurrency);

  Future<void> worker() async {
    while (true) {
      if (stop()) return;
      final i = next++;
      if (i >= cards.length) return;
      final c = cards[i];
      onCard(c.copyWith(status: CheckStatus.checking, message: ''));
      CheckResult r;
      try {
        r = await engine.check(c);
      } catch (e) {
        r = CheckResult(status: CheckStatus.unknown, message: 'fallo: $e');
      }

      var enriched = c;
      if (cfg.enrich && r.status != CheckStatus.unknown && c.bin.length >= 6) {
        final info = await engine.lookupBin(c.bin);
        if (info != null) {
          final scheme = (info['scheme'] ?? '').toString();
          final type = (info['type'] ?? '').toString();
          final brand2 = (info['brand'] ?? '').toString();
          final bank = info['bank'];
          final country = info['country'];
          enriched = c.copyWith(
            kind: type,
            level: brand2,
            bank: bank is Map ? (bank['name'] ?? '').toString() : '',
            country: country is Map ? (country['alpha2'] ?? '').toString() : '',
            brand: scheme.isNotEmpty ? scheme : c.brand,
          );
        }
      }

      done++;
      onCard(
        enriched.copyWith(
          status: r.status,
          message: r.message,
          gateway: r.gateway,
          latencyMs: r.latencyMs,
          checkedAt: DateTime.now(),
        ),
      );
      onProgress(done, cards.length);
    }
  }

  await Future.wait(List<Future<void>>.generate(workers, (_) => worker()));
  engine.dispose();
}
