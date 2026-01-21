import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';

/// Container de ícone do design system
class AppIconContainer extends StatelessWidget {
  const AppIconContainer({
    super.key,
    required this.icon,
    this.size = 40,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? iconColor.withValues(alpha: 0.15);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.25),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size * 0.5,
      ),
    );
  }
}
