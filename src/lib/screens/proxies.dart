import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../checker.dart';
import '../core.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class ProxiesScreen extends ConsumerStatefulWidget {
  const ProxiesScreen({super.key});
  @override
  ConsumerState<ProxiesScreen> createState() => _ProxiesScreenState();
}

class _ProxiesScreenState extends ConsumerState<ProxiesScreen> {
  final _text = TextEditingController();
  bool _busy = false;

  void _add() {
    final out = <ProxyNode>[];
    for (var line in _text.text.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final host = parts[0];
      final port = int.tryParse(parts[1]) ?? 0;
      if (port == 0) continue;
      out.add(ProxyNode(
        id: newId(),
        host: host,
        port: port,
        user: parts.length > 2 ? parts[2] : '',
        pass: parts.length > 3 ? parts[3] : '',
      ));
    }
    if (out.isEmpty) return;
    ref.read(proxiesProvider.notifier).addAll(out);
    _text.clear();
  }

  Future<void> _test(ProxyNode p) async {
    setState(() => _busy = true);
    final engine = CheckEngine(ref.read(settingsProvider));
    final r = await engine.exitInfo(p);
    engine.dispose();
    final ok = r != 'fallo' && r != 'sin respuesta';
    ref.read(proxiesProvider.notifier).update(
          p.copyWith(health: ok ? ProxyHealth.ok : ProxyHealth.down),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.label} -> $r')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(proxiesProvider);
    final cfg = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Proxies', style: AppTextStyles.title),
        SwitchListTile(
          value: cfg.useProxies,
          onChanged: (v) => ref.read(settingsProvider.notifier).setProxies(v),
          activeColor: AppColors.lime,
          title: const Text('Usar proxies', style: AppTextStyles.body),
          subtitle: const Text('rota por la lista en cada intento', style: AppTextStyles.tiny),
        ),
        const SectionHeader('Anadir (host:puerto:user:pass)'),
        TextField(
          controller: _text,
          maxLines: 4,
          style: AppTextStyles.mono,
          decoration: const InputDecoration(hintText: '1.2.3.4:8080:user:pass'),
        ),
        const SizedBox(height: 10),
        NeonButton(label: 'Anadir', icon: Icons.add, expand: true, onPressed: _add),
        const SectionHeader('Lista'),
        for (final p in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassPanel(
              pad: 10,
              child: Row(
                children: [
                  Expanded(child: Text(p.label, style: AppTextStyles.mono)),
                  Text(
                    p.health.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.health == ProxyHealth.ok ? AppColors.lime : AppColors.textMid,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.speed, size: 18),
                    onPressed: _busy ? null : () => _test(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => ref.read(proxiesProvider.notifier).remove(p.id),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}
