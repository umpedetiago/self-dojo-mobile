import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';

/// Título de seção do design system
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
