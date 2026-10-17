import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'queue.dart';
import 'repos.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(const Settings()) {
    final raw = Vault.get('settings');
    if (raw.isEmpty) return;
    try {
      state = Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _save() async {
    await Vault.put('settings', jsonEncode(state.toJson()));
  }

  Future<void> setEngine(String v) async {
    state = state.copyWith(engine: v);
    await _save();
  }

  Future<void> setStripeSk(String v) async {
    state = state.copyWith(stripeSk: v.trim());
    await _save();
  }

  Future<void> setDorkillKey(String v) async {
    state = state.copyWith(dorkillKey: v.trim());
    await _save();
  }

  Future<void> setDoh(bool v) async {
    state = state.copyWith(doh: v);
    await _save();
  }

  Future<void> setProxies(bool v) async {
    state = state.copyWith(useProxies: v);
    await _save();
  }

  Future<void> setConcurrency(int v) async {
    state = state.copyWith(concurrency: v);
    await _save();
  }

  Future<void> setTimeout(int v) async {
    state = state.copyWith(timeoutSec: v);
    await _save();
  }

  Future<void> setRetries(int v) async {
    state = state.copyWith(retries: v);
    await _save();
  }

  Future<void> setBiometrics(bool v) async {
    state = state.copyWith(biometrics: v);
    await _save();
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, List<CreditCard>>((ref) {
  return CardsNotifier();
});

class CardsNotifier extends StateNotifier<List<CreditCard>> {
  CardsNotifier() : super(const <CreditCard>[]) {
    final raw = Vault.get('cards');
    if (raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => CreditCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  Future<void> save() async {
    await Vault.put('cards', jsonEncode(state.map((c) => c.toJson()).toList()));
  }

  void addAll(List<CreditCard> cards) {
    final seen = state.map((c) => c.key).toSet();
    final add = <CreditCard>[];
    for (final c in cards) {
      if (seen.add(c.key)) add.add(c);
    }
    state = [...state, ...add];
    save();
  }

  void update(CreditCard card) {
    state = [for (final c in state) c.id == card.id ? card : c];
    save();
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    save();
  }

  void clear() {
    state = const <CreditCard>[];
    save();
  }

  void resetResults() {
    state = [
      for (final c in state)
        c.copyWith(status: CheckStatus.unchecked, message: '', gateway: '', latencyMs: 0),
    ];
    save();
  }
}

final proxiesProvider = StateNotifierProvider<ProxiesNotifier, List<ProxyNode>>((ref) {
  return ProxiesNotifier();
});

class ProxiesNotifier extends StateNotifier<List<ProxyNode>> {
  ProxiesNotifier() : super(const <ProxyNode>[]) {
    final raw = Vault.get('proxies');
    if (raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => ProxyNode.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  Future<void> save() async {
    await Vault.put('proxies', jsonEncode(state.map((p) => p.toJson()).toList()));
  }

  void addAll(List<ProxyNode> nodes) {
    state = [...state, ...nodes];
    save();
  }

  void update(ProxyNode p) {
    state = [for (final x in state) x.id == p.id ? p : x];
    save();
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    save();
  }
}

class RunState {
  const RunState({this.running = false, this.done = 0, this.total = 0, this.note = ''});
  final bool running;
  final int done;
  final int total;
  final String note;
}

final runProvider = StateNotifierProvider<RunNotifier, RunState>((ref) {
  return RunNotifier(ref);
});

class RunNotifier extends StateNotifier<RunState> {
  RunNotifier(this.ref) : super(const RunState());

  final Ref ref;
  bool _stop = false;

  void toggle() {
    if (state.running) {
      _stop = true;
    } else {
      start();
    }
  }

  Future<void> start() async {
    final cfg = ref.read(settingsProvider);
    final list = ref.read(cardsProvider);
    final pool = ref.read(proxiesProvider);
    if (list.isEmpty) return;

    _stop = false;
    final total = list.length;
    state = RunState(running: true, total: total, note: cfg.mode);

    await runMass(
      cards: list,
      cfg: cfg,
      proxies: pool,
      stop: () => _stop,
      onCard: (c) {
        ref.read(cardsProvider.notifier).update(c);
      },
      onProgress: (done, t) {
        state = RunState(running: true, done: done, total: t, note: cfg.mode);
      },
    );

    await ref.read(cardsProvider.notifier).save();
    final d = state.done;
    state = RunState(running: false, done: d, total: total, note: 'listo');
  }
}
