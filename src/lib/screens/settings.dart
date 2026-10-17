import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../checker.dart';
import '../core.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _sk = TextEditingController();
  final _dk = TextEditingController();
  String _keyMsg = '';
  String _probeMsg = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(settingsProvider);
    _sk.text = cfg.stripeSk;
    _dk.text = cfg.dorkillKey;
  }

  Future<void> _testKey() async {
    final sk = _sk.text.trim().replaceAll(RegExp(r'\s'), '');
    if (sk.isEmpty) {
      setState(() => _keyMsg = 'pega la key primero');
      return;
    }
    if (!sk.startsWith('sk_')) {
      setState(() => _keyMsg = 'no empieza por sk_ · pegaste la publica?');
      return;
    }
    setState(() {
      _busy = true;
      _keyMsg = 'probando...';
    });
    try {
      final r = await http.get(
        Uri.parse(stripeBalanceUrl),
        headers: {'Authorization': 'Bearer $sk'},
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _keyMsg = r.statusCode == 200 ? 'key OK' : 'key rechazada (${r.statusCode})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _keyMsg = 'sin red';
      });
    }
  }

  Future<void> _probe() async {
    setState(() {
      _busy = true;
      _probeMsg = 'probando...';
    });
    final cfg = ref.read(settingsProvider);
    final engine = CheckEngine(cfg);
    final a = await engine.probe(stripeTokenUrl);
    final b = await engine.probe(stripePiUrl);
    engine.dispose();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _probeMsg = 'token: $a\nauth: $b';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Ajustes', style: AppTextStyles.title),
        const SectionHeader('Modo de comprobacion'),
        GlassPanel(
          child: Column(
            children: [
              for (final m in const [
                ('stripe', 'Token (pk, solo formato)'),
                ('both', 'Cascada (stripe + dorkill)'),
                ('dorkill', 'Dorkill (api key)'),
              ])
                RadioListTile<String>(
                  value: m.$1,
                  groupValue: cfg.engine,
                  onChanged: (v) {
                    if (v != null) ref.read(settingsProvider.notifier).setEngine(v);
                  },
                  activeColor: AppColors.lime,
                  dense: true,
                  title: Text(m.$2, style: AppTextStyles.caption),
                ),
              const Divider(color: AppColors.stroke),
              Text(
                cfg.authOn
                    ? 'MODO ACTIVO: auth real (la key privada manda)'
                    : 'MODO ACTIVO: ${cfg.mode}',
                style: TextStyle(
                  color: cfg.authOn ? AppColors.lime : AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Stripe SECRET key (sk_test_...)'),
        TextField(
          controller: _sk,
          style: AppTextStyles.mono,
          decoration: const InputDecoration(hintText: 'sk_test_...'),
          onChanged: (v) => ref.read(settingsProvider.notifier).setStripeSk(v),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            NeonButton(
              label: 'Probar key',
              icon: Icons.vpn_key,
              color: AppColors.cyan,
              onPressed: _busy ? null : _testKey,
            ),
            const SizedBox(width: 10),
            if (_keyMsg.isNotEmpty)
              Expanded(child: Text(_keyMsg, style: AppTextStyles.caption)),
          ],
        ),
        const Text(
          'Con la key privada la app hace una autorizacion real de \$1 con captura manual: no cobra, solo retiene.',
          style: AppTextStyles.tiny,
        ),
        const SectionHeader('Dorkill API key'),
        TextField(
          controller: _dk,
          style: AppTextStyles.mono,
          decoration: const InputDecoration(hintText: 'opcional'),
          onChanged: (v) => ref.read(settingsProvider.notifier).setDorkillKey(v),
        ),
        const SectionHeader('Red'),
        SwitchListTile(
          value: cfg.doh,
          onChanged: (v) => ref.read(settingsProvider.notifier).setDoh(v),
          activeColor: AppColors.lime,
          title: const Text('DNS por HTTPS (DoH)', style: AppTextStyles.body),
          subtitle: const Text('evita que el operador bloquee', style: AppTextStyles.tiny),
        ),
        const SizedBox(height: 6),
        Text('concurrencia: ${cfg.concurrency}', style: AppTextStyles.body),
        Slider(
          value: cfg.concurrency.toDouble(),
          min: 1,
          max: 24,
          onChanged: (v) => ref.read(settingsProvider.notifier).setConcurrency(v.round()),
        ),
        Text('timeout: ${cfg.timeoutSec}s', style: AppTextStyles.body),
        Slider(
          value: cfg.timeoutSec.toDouble(),
          min: 5,
          max: 60,
          onChanged: (v) => ref.read(settingsProvider.notifier).setTimeout(v.round()),
        ),
        Text('reintentos: ${cfg.retries}', style: AppTextStyles.body),
        Slider(
          value: cfg.retries.toDouble(),
          min: 0,
          max: 4,
          onChanged: (v) => ref.read(settingsProvider.notifier).setRetries(v.round()),
        ),
        const SizedBox(height: 8),
        NeonButton(
          label: 'Probar conexion a Stripe',
          icon: Icons.network_check,
          color: AppColors.cyan,
          expand: true,
          onPressed: _busy ? null : _probe,
        ),
        if (_probeMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_probeMsg, style: AppTextStyles.caption),
        ],
        const SectionHeader('Version'),
        Text('$appVersion ($appBuild)', style: AppTextStyles.caption),
        const SizedBox(height: 30),
      ],
    );
  }
}
