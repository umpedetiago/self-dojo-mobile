import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/theme/app_text_styles.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';

/// Componente de toggle para seleção de role (Student/Academy Owner)
class AppRoleToggle extends StatelessWidget {
  const AppRoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Student',
              isSelected: selectedRole == UserRole.student,
              onTap: () => onRoleChanged(UserRole.student),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'Academy Owner',
              isSelected: selectedRole == UserRole.owner,
              onTap: () => onRoleChanged(UserRole.owner),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceDark
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
