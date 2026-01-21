import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';

/// Linha de informação do design system
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.spacing = 12,
  });

  final IconData icon;
  final String label;
  final String value;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textTertiaryDark,
          ),
          SizedBox(width: spacing),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
