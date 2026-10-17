import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';
import 'widgets.dart';

class RunBar extends ConsumerWidget {
  const RunBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);
    final cards = ref.watch(cardsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (run.running)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: run.total == 0 ? 0 : run.done / run.total,
                    minHeight: 6,
                    backgroundColor: AppColors.stroke,
                    valueColor: const AlwaysStoppedAnimation(AppColors.lime),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${run.done} / ${run.total} · ${run.note}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  label: run.running ? 'Parar' : 'Comprobar todo',
                  icon: run.running ? Icons.stop : Icons.play_arrow,
                  color: run.running ? AppColors.red : AppColors.lime,
                  expand: true,
                  onPressed: cards.isEmpty
                      ? null
                      : () => ref.read(runProvider.notifier).toggle(),
                ),
              ),
              const SizedBox(width: 10),
              NeonButton(
                label: 'Limpiar resultados',
                icon: Icons.refresh,
                color: AppColors.textMid,
                onPressed: run.running
                    ? null
                    : () => ref.read(cardsProvider.notifier).resetResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
