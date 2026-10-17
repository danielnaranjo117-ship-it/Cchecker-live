import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import '../value.dart';
import '../widgets.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});
  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _search = TextEditingController();
  String _filter = 'todas';

  static const _filters = ['todas', 'vivas', 'cobrables', 'muertas', 'sin comprobar'];

  bool _match(CreditCard c) {
    final q = _search.text.trim();
    if (q.isNotEmpty) {
      final hay = '${c.pan} ${c.bank} ${c.country} ${c.brand} ${c.message}'.toLowerCase();
      if (!hay.contains(q.toLowerCase())) return false;
    }
    switch (_filter) {
      case 'vivas':
        return c.status == CheckStatus.live;
      case 'cobrables':
        return c.status.cobrable;
      case 'muertas':
        return c.status == CheckStatus.dead;
      case 'sin comprobar':
        return c.status == CheckStatus.unchecked;
      default:
        return true;
    }
  }

  Color _color(CheckStatus s) {
    switch (s) {
      case CheckStatus.live:
        return AppColors.lime;
      case CheckStatus.noFunds:
        return AppColors.amber;
      case CheckStatus.need3ds:
        return AppColors.cyan;
      case CheckStatus.cvcFail:
      case CheckStatus.avsFail:
        return AppColors.violet;
      case CheckStatus.dead:
        return AppColors.red;
      case CheckStatus.checking:
        return AppColors.cyan;
      default:
        return AppColors.textMid;
    }
  }

  Future<void> _addDialog() async {
    final pan = TextEditingController();
    final mm = TextEditingController();
    final yy = TextEditingController();
    final cvv = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Anadir tarjeta', style: AppTextStyles.body),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pan,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'numero'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mm,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'MM'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: yy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'AA'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: cvv,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CVV'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('cancelar'),
          ),
          TextButton(
            onPressed: () {
              final p = digitsOf(pan.text);
              if (p.length < 12) return;
              final card = CreditCard(
                id: newId(),
                pan: p,
                expMonth: int.tryParse(mm.text) ?? 1,
                expYear: int.tryParse(yy.text) ?? 30,
                cvv: digitsOf(cvv.text),
                brand: brandOf(p),
                bin: p.substring(0, 6),
              );
              ref.read(cardsProvider.notifier).addAll([card]);
              Navigator.pop(ctx);
            },
            child: const Text('anadir'),
          ),
        ],
      ),
    );
  }

  void _detail(CreditCard c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.pan, style: AppTextStyles.mono),
            const SizedBox(height: 4),
            Text('${c.exp}  ·  ${c.cvv}  ·  ${c.brand}', style: AppTextStyles.caption),
            const SizedBox(height: 12),
            _row('estado', '${c.status.label}  ${c.message}'),
            _row('via', c.gateway.isEmpty ? '-' : c.gateway),
            _row('latencia', '${c.latencyMs} ms'),
            _row('banco', c.bank.isEmpty ? '-' : c.bank),
            _row('pais', c.country.isEmpty ? '-' : c.country),
            _row('nivel', c.level.isEmpty ? '-' : c.level),
            _row('saldo estimado', estimateBalance(c).text),
            const SizedBox(height: 14),
            Row(
              children: [
                NeonButton(
                  label: 'copiar',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: c.key));
                  },
                ),
                const SizedBox(width: 10),
                NeonButton(
                  label: 'borrar',
                  icon: Icons.delete_outline,
                  color: AppColors.red,
                  onPressed: () {
                    ref.read(cardsProvider.notifier).remove(c.id);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(k, style: AppTextStyles.caption)),
            Expanded(child: Text(v, style: AppTextStyles.body)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider).where(_match).toList();
    final all = ref.watch(cardsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              const Expanded(child: Text('Boveda', style: AppTextStyles.title)),
              Text('${fmtInt(all.length)} tarjetas', style: AppTextStyles.caption),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'buscar pan, banco, pais...',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter == f
                            ? AppColors.lime.withOpacity(0.15)
                            : AppColors.panel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _filter == f ? AppColors.lime : AppColors.stroke,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: _filter == f ? AppColors.lime : AppColors.textMid,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? const Center(child: Text('nada por aqui', style: AppTextStyles.caption))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: cards.length,
                  itemBuilder: (ctx, i) {
                    final c = cards[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _detail(c),
                        child: GlassPanel(
                          pad: 12,
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _color(c.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.pan, style: AppTextStyles.mono),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.exp} · ${c.brand} · ${c.message.isEmpty ? c.status.label : c.message}',
                                      style: AppTextStyles.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                c.status.tag,
                                style: TextStyle(
                                  color: _color(c.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              NeonButton(label: 'Anadir', icon: Icons.add, onPressed: _addDialog),
              const SizedBox(width: 10),
              NeonButton(
                label: 'Exportar',
                icon: Icons.share,
                color: AppColors.cyan,
                onPressed: all.isEmpty
                    ? null
                    : () {
                        final data = all
                            .map((c) => '${c.pan}|${pad2(c.expMonth)}|${pad2(c.expYear)}|${c.cvv}')
                            .join('\n');
                        Share.share(data, subject: 'CCheker Live');
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
