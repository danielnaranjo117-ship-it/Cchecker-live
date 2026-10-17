import 'package:flutter/material.dart';

import 'theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.pad = 14});
  final Widget child;
  final double pad;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: child,
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Text(text.toUpperCase(), style: AppTextStyles.tiny),
      );
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.lime,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    final c = on ? color : AppColors.textMid;
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.withOpacity(on ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(on ? 0.7 : 0.3)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: c),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: body,
    );
  }
}
