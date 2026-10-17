import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bin_gen.dart';
import '../import_engine.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});
  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _text = TextEditingController();
  final _bin = TextEditingController(text: '424242');
  ImportResult? _res;
  bool _repair = true;
  int _genCount = 10;

  void _parse() {
    final r = parseCards(_text.text, repair: _repair);
    setState(() => _res = r);
  }

  void _generate() {
    final cards = generate(GenSpec(bin: _bin.text, count: _genCount));
    setState(() => _res = ImportResult(cards: cards));
  }

  void _save() {
    final r = _res;
    if (r == null || r.cards.isEmpty) return;
    ref.read(cardsProvider.notifier).addAll(r.cards);
    setState(() => _res = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${r.cards.length} guardadas')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = _res;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Importar', style: AppTextStyles.title),
        const SizedBox(height: 6),
        const Text(
          'Pega tarjetas: numero|MM|AA|CVV, una por linea.',
          style: AppTextStyles.caption,
        ),
        const SectionHeader('Pegar'),
        TextField(
          controller: _text,
          maxLines: 7,
          style: AppTextStyles.mono,
          decoration: const InputDecoration(hintText: '4242424242424242|12|30|123'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NeonButton(label: 'Analizar', icon: Icons.search, expand: true, onPressed: _parse),
            ),
            const SizedBox(width: 10),
            NeonButton(
              label: 'Limpiar',
              color: AppColors.textMid,
              onPressed: () => setState(() {
                _text.clear();
                _res = null;
              }),
            ),
          ],
        ),
        SwitchListTile(
          value: _repair,
          onChanged: (v) => setState(() => _repair = v),
          activeColor: AppColors.lime,
          title: const Text('Reparar digito de control', style: AppTextStyles.body),
          subtitle: const Text('corrige numeros con Luhn roto', style: AppTextStyles.tiny),
        ),
        const SectionHeader('Generar desde un BIN'),
        GlassPanel(
          child: Column(
            children: [
              TextField(
                controller: _bin,
                style: AppTextStyles.mono,
                decoration: const InputDecoration(labelText: 'BIN o prefijo'),
              ),
              const SizedBox(height: 8),
              Text('cantidad $_genCount', style: AppTextStyles.body),
              Slider(
                value: _genCount.toDouble(),
                min: 1,
                max: 200,
                onChanged: (v) => setState(() => _genCount = v.round()),
              ),
              NeonButton(
                label: 'Generar',
                icon: Icons.auto_fix_high,
                color: AppColors.violet,
                expand: true,
                onPressed: _generate,
              ),
            ],
          ),
        ),
        if (res != null) ...[
          const SectionHeader('Vista previa'),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${res.cards.length} validas',
                  style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${res.duplicates} repetidas · ${res.junk} basura · ${res.fixed} reparadas · ${res.expired} vencidas',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                NeonButton(
                  label: 'Guardar ${res.cards.length}',
                  icon: Icons.save,
                  expand: true,
                  onPressed: res.cards.isEmpty ? null : _save,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }
}
