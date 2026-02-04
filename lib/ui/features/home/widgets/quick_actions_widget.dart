import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/ui/components/app_quick_action_button.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Widget de ações rápidas da tela home
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    // Verifica se é owner
    final isOwner = profile.isOwner;
    // Verifica se tem academia vinculada (como aluno)
    final hasAcademy = profile.academyId != null && profile.academyId!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (isOwner)
                Expanded(
                  child: AppQuickActionButton(
                    icon: Icons.business,
                    label: 'Minha Academia',
                    color: AppColors.primary,
                    onTap: () => context.push('/academy/select'),
                  ),
                )
              else if (hasAcademy)
                Expanded(
                  child: AppQuickActionButton(
                    icon: Icons.home_work,
                    label: 'Minha Academia',
                    color: AppColors.primary,
                    onTap: () {
                      // TODO: ir para visualização da academia do aluno
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Visualização da academia em desenvolvimento'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: AppQuickActionButton(
                    icon: Icons.search,
                    label: 'Buscar Academia',
                    color: AppColors.primary,
                    onTap: () => context.push('/academy/search'),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: AppQuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Check-in',
                  color: AppColors.secondary,
                  onTap: () => context.push('/checkin'),
                ),
              ),
            ],
          ),
          // Segunda linha de ações (se for aluno com academia)
          if (hasAcademy && !isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppQuickActionButton(
                      icon: Icons.history,
                      label: 'Histórico',
                      color: AppColors.accent,
                      onTap: () => context.push('/checkin/history'),
                    ),
                  ),
                ],
              ),
            ),
          if (!isOwner && !hasAcademy)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppQuickActionButton(
                      icon: Icons.add_business,
                      label: 'Criar Academia',
                      color: AppColors.accent,
                      onTap: () => context.push('/academy/create'),
                    ),
                  ),
                ],
              ),
            ),
          // Botão adicional para owner: buscar academia também
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: AppQuickActionButton(
                  icon: Icons.search,
                  label: 'Buscar Academia',
                  color: AppColors.accent,
                  onTap: () => context.push('/academy/search'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
