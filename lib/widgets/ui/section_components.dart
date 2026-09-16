import 'package:flutter/material.dart';

/// رأس قسم موحّد مع أيقونة في خلفية ملونة، يُستخدم في كامل لوحة التحكم.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = iconColor ?? colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة تحتوي بيانات صغيرة (قيمة + عنوان) متدرجة الخلفية بشكل احترافي.
class GradientBanner extends StatelessWidget {
  const GradientBanner({
    super.key,
    required this.badge,
    this.badgeColor = Colors.white,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.trailing,
    this.gradient,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget? badge;
  final Color badgeColor;
  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final List<Color>? gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors:
              gradient ??
              (isDark
                  ? [
                      colorScheme.surface,
                      colorScheme.surfaceTint.withValues(alpha: 0.15),
                    ]
                  : [colorScheme.primary, colorScheme.secondary]),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (badge != null) ...[badge!, const SizedBox(width: 16)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style:
                        titleStyle ??
                        const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                  ),
                if (title != null && subtitle != null)
                  const SizedBox(height: 6),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style:
                        subtitleStyle ??
                        TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    );
  }
}
