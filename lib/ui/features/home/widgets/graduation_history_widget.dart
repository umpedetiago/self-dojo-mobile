import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Widget de histórico de graduações
class GraduationHistoryWidget extends StatelessWidget {
  const GraduationHistoryWidget({
    super.key,
    required this.profile,
    required this.martialArt,
  });

  final UserProfile profile;
  final MartialArt martialArt;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Usa histórico da modalidade matriculada se disponível, senão legado
    final graduationHistory = profile.enrolledModalities.isNotEmpty
        ? profile.enrolledModalities.first.graduationHistory
        : profile.graduationHistory;

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
            'Histórico de Graduações',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...graduationHistory.reversed.take(5).map((history) {
            final belt = martialArt.getBeltById(history.beltId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: belt?.color ?? Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          belt?.name ?? 'Faixa',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(history.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (history.degree > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${history.degree}º grau',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
