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
            final classesUntilNextDegree = modality.classesUntilNextDegree;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Total de aulas na modalidade
                            _InfoChip(
                              icon: Icons.fitness_center,
                              label: '${modality.totalClasses} aulas',
                            ),
                            const SizedBox(width: 8),
                            // Próxima faixa (se houver)
                            if (modality.classesUntilNextDegree > 0)
                              _InfoChip(
                                icon: Icons.trending_up,
                                label: '${modality.classesUntilNextDegree} até a próxima faixa',
                              ),
                            const SizedBox(width: 8),
                            // Próximo grau (se houver)
                            if (classesUntilNextDegree > 0)
                              _InfoChip(
                                icon: Icons.stacked_line_chart,
                                label: '$classesUntilNextDegree até o próximo grau',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (belt != null)
                    Container(
                      width: 40,
                      height: 12,
                      margin: const EdgeInsets.only(left: 8, top: 4),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
