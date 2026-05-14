// lib/widgets/common/common_widgets.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.onPressed, required this.isLoading,
      required this.label, this.icon, this.color});
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color ?? AppTheme.primaryBlue),
      child: isLoading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
    ),
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding,
      this.color, this.borderColor, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final Color? color, borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.07)),
      ),
      child: child,
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.actionLabel});
  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (action != null)
        TextButton(onPressed: action, child: Text(actionLabel ?? 'Ver todo →',
            style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12))),
    ],
  );
}

class BadgeLabel extends StatelessWidget {
  const BadgeLabel(this.text, {super.key, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.value, required this.max,
      required this.color, this.height = 6});
  final double value, max, height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (value / max.clamp(0.001, double.infinity)).clamp(0.0, 1.0);
    final c   = pct > 0.9 ? AppTheme.dangerRed : pct > 0.7 ? AppTheme.warningAmber : color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: pct, minHeight: height,
        backgroundColor: Colors.white12,
        valueColor: AlwaysStoppedAnimation(c),
      ),
    );
  }
}

class OnlineDot extends StatelessWidget {
  const OnlineDot({super.key, this.online = true});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = online ? AppTheme.primaryGreen : AppTheme.textSecondary;
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 4)]),
    );
  }
}
