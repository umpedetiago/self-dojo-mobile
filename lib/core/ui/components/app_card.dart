import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';
import 'package:self_dojo_mobile/core/ui/components/app_button.dart';

/// Card de estatística do design system
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.maxValue,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? maxValue;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              if (maxValue != null)
                Text(
                  maxValue!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
                ),
            ],
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Card de informação do design system
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  final String title;
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
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
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Card de menu item do design system
class AppMenuItemCard extends StatelessWidget {
  const AppMenuItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimaryDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textTertiaryDark,
        ),
      ),
    );
  }
}

/// Card de banner do design system
class AppBannerCard extends StatelessWidget {
  const AppBannerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.secondary.withValues(alpha: 0.3),
              ],
            ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            AppTextButton(
              label: actionLabel!,
              onPressed: onAction!,
            ),
        ],
      ),
    );
  }
}
