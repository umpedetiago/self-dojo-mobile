import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';

/// Divisor do design system
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height,
    this.indent,
    this.endIndent,
  });

  final double? height;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.surfaceVariantDark,
      height: height ?? 32,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
