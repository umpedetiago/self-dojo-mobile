import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Widget de modalidades matriculadas
class EnrolledModalitiesWidget extends StatelessWidget {
  const EnrolledModalitiesWidget({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minhas Modalidades',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...profile.enrolledModalities.map((modality) {
            final martialArt = modality.martialArt;
            final belt = modality.currentBelt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: martialArt.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      martialArt.icon,
                      color: martialArt.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          martialArt.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          belt != null
                              ? '${belt.name}${modality.graduation.degree > 0 ? ' - ${modality.graduation.degree}º grau' : ''}'
                              : 'Sem graduação',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (belt != null)
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: belt.color,
                        borderRadius: BorderRadius.circular(2),
                        border: belt.color == Colors.white
                            ? Border.all(color: Colors.grey.shade400)
                            : null,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
