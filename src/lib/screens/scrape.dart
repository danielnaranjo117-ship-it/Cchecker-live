import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../import_engine.dart';
import '../providers.dart';
import '../scraper.dart';
import '../theme.dart';
import '../widgets.dart';

class ScrapeScreen extends ConsumerStatefulWidget {
  const ScrapeScreen({super.key});
  @override
  ConsumerState<ScrapeScreen> createState() => _ScrapeScreenState();
}

class _ScrapeScreenState extends ConsumerState<ScrapeScreen> {
  final _url = TextEditingController();
  String _note = '';
  bool _busy = false;

  Future<void> _go() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _busy = true;
      _note = 'descargando...';
    });
    final cfg = ref.read(settingsProvider);
    final r = await fetchList(url, cfg);
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _busy = false;
        _note = 'fallo: ${r.note}';
      });
      return;
    }
    final parsed = parseCards(r.text);
    ref.read(cardsProvider.notifier).addAll(parsed.cards);
    setState(() {
      _busy = false;
      _note = '${parsed.cards.length} tarjetas guardadas (${r.note})';
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Fuentes', style: AppTextStyles.title),
          const SizedBox(height: 6),
          const Text(
            'Pega la URL de una lista. Se descarga, se parsea y se guarda.',
            style: AppTextStyles.caption,
          ),
          const SectionHeader('URL'),
          TextField(
            controller: _url,
            style: AppTextStyles.mono,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          const SizedBox(height: 10),
          NeonButton(
            label: _busy ? 'trabajando...' : 'Descargar y guardar',
            icon: Icons.cloud_download,
            expand: true,
            onPressed: _busy ? null : _go,
          ),
          if (_note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_note, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 30),
        ],
      );
}
