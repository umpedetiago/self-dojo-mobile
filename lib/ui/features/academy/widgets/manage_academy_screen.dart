import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de gerenciamento da academia (Dashboard do Owner)
class ManageAcademyScreen extends StatelessWidget {
  const ManageAcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userId = authViewModel.user.id;

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => AcademyViewModel(
        academyRepository: ctx.read<AcademyRepository>(),
        profileRepository: ctx.read<ProfileRepository>(),
        userId: userId,
      ),
      child: const _ManageAcademyContent(),
    );
  }
}

class _ManageAcademyContent extends StatelessWidget {
  const _ManageAcademyContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AcademyViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    // Se não tem academia, redireciona para criar
    if (!viewModel.hasAcademy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/academy/create');
      });
      return const SizedBox.shrink();
    }

    final academy = viewModel.academy;

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context, academy, viewModel),
              ),

              // Trial Banner
              if (viewModel.isOnTrial)
                SliverToBoxAdapter(
                  child: _buildTrialBanner(viewModel),
                ),

              // Stats Cards
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildStatCard(
                      icon: Icons.people,
                      label: 'Alunos',
                      value: '${viewModel.studentCount}',
                      maxValue: viewModel.isOnTrial
                          ? '/ 10'
                          : '/ ${academy.subscription?.maxStudents ?? '∞'}',
                      color: AppColors.primary,
                      onTap: () => context.push('/academy/students'),
                    ),
                    _buildStatCard(
                      icon: Icons.sports_martial_arts,
                      label: 'Modalidades',
                      value: '${academy.modalities.length}',
                      maxValue: '/ ${academy.subscription?.maxModalities ?? '∞'}',
                      color: AppColors.secondary,
                      onTap: () => context.push('/academy/modalities'),
                    ),
                    _buildStatCard(
                      icon: Icons.school,
                      label: 'Professores',
                      value: '${academy.totalTeachers}',
                      maxValue: '/ ${academy.subscription?.maxTeachers ?? '∞'}',
                      color: AppColors.accent,
                      onTap: () => context.push('/academy/teachers'),
                    ),
                    _buildStatCard(
                      icon: Icons.pending_actions,
                      label: 'Solicitações',
                      value: '${viewModel.pendingRequestsCount}',
                      color: Colors.orange,
                      onTap: () async {
                        await context.push('/academy/requests');
                        viewModel.refreshPendingRequestsCount();
                      },
                    ),
                  ]),
                ),
              ),

              // Menu Items
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gerenciamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        icon: Icons.sports_martial_arts,
                        title: 'Modalidades',
                        subtitle: 'Gerenciar artes marciais e graduações',
                        onTap: () => context.push('/academy/modalities'),
                      ),
                      _buildMenuItem(
                        icon: Icons.people,
                        title: 'Alunos',
                        subtitle: 'Ver e gerenciar alunos',
                        onTap: () => context.push('/academy/students'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person_add,
                        title: 'Solicitações',
                        subtitle: 'Aprovar novos alunos',
                        onTap: () async {
                          await context.push('/academy/requests');
                          viewModel.refreshPendingRequestsCount();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.school,
                        title: 'Equipe',
                        subtitle: 'Professores e instrutores',
                        onTap: () => context.push('/academy/teachers'),
                      ),
                      _buildMenuItem(
                        icon: Icons.edit,
                        title: 'Editar Academia',
                        subtitle: 'Informações da academia',
                        onTap: () => context.push('/academy/edit'),
                      ),
                      _buildMenuItem(
                        icon: Icons.credit_card,
                        title: 'Assinatura',
                        subtitle: academy.subscription?.isTrial == true
                            ? 'Trial - ${viewModel.trialDaysRemaining} dias restantes'
                            : 'Gerenciar plano',
                        onTap: () => context.push('/academy/subscription'),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration get _backgroundDecoration => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a3e),
            AppColors.backgroundDark,
          ],
        ),
      );

  Widget _buildHeader(
      BuildContext context, Academy academy, AcademyViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/academy/edit'),
                icon: const Icon(
                  Icons.settings,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  image: academy.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(academy.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: academy.logoUrl == null
                    ? const Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      academy.modalities
                          .map((m) => m.martialArt.shortName)
                          .join(' • '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(AcademyViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          const Icon(Icons.card_giftcard, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período de Trial',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${viewModel.trialDaysRemaining} dias restantes • Até 10 alunos',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, // TODO: ir para assinatura
            child: const Text('Assinar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? maxValue,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                if (maxValue != null)
                  Text(
                    maxValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
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

