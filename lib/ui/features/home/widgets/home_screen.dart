import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/ui/components/app_card.dart';
import 'package:self_dojo_mobile/core/ui/components/app_info_row.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/belt_display.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/enrolled_modalities_widget.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/graduation_history_widget.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/profile_header.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/quick_actions_widget.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/stats_card.dart';

/// Tela Home principal
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializa o ProfileService com os dados do usuário autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final profileService = context.read<ProfileService>();
      final user = authViewModel.user;

      if (user.id.isNotEmpty) {
        profileService.init(
          user.id,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userId = authViewModel.user.id;

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const _HomeContent();
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    final authViewModel = context.read<AuthViewModel>();

    if (profileService.isLoading) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final profile = profileService.profile;

    final martialArt = profile.martialArt;
    final currentBelt = profile.currentBelt;
    final nextBelt = profile.nextBelt;

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => profileService.refresh(),
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            child: CustomScrollView(
              slivers: [
                // Header com perfil
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: profile,
                    onLogout: () => _showLogoutDialog(context, authViewModel),
                    onEditProfile: () => context.push('/profile/edit'),
                  ),
                ),

              // Faixa atual (usa modalidade matriculada se disponível, senão legado)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: BeltDisplay(
                    martialArt: martialArt,
                    belt: currentBelt,
                    degree: profile.enrolledModalities.isNotEmpty
                        ? profile.enrolledModalities.first.graduation.degree
                        : profile.graduation?.degree ?? 0,
                    graduation: profile.enrolledModalities.isNotEmpty
                        ? profile.enrolledModalities.first.graduation
                        : profile.graduation,
                  ),
                ),
              ),

              // Cards de estatísticas
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildListDelegate([
                    StatsCard(
                      icon: Icons.fitness_center,
                      label: 'Total de Aulas',
                      value: '${profile.totalClassesAll}',
                      color: AppColors.primary,
                      onTap: (profile.academyId != null && profile.academyId!.isNotEmpty && !profile.isOwner)
                          ? () => context.push('/checkin/history')
                          : null,
                    ),
                    StatsCard(
                      icon: Icons.schedule,
                      label: 'Tempo de Treino',
                      value: _formatTrainingTime(profile.trainingTime),
                      color: AppColors.secondary,
                    ),
                    StatsCard(
                      icon: Icons.emoji_events,
                      label: 'Competições',
                      value: '${profile.competitions.length}',
                      color: AppColors.accent,
                    ),
                    if (nextBelt != null)
                      StatsCard(
                        icon: Icons.trending_up,
                        label: 'Próxima Faixa',
                        value: '${profile.classesUntilPromotion} aulas',
                        color: _getBeltColor(nextBelt),
                      )
                    else
                      StatsCard(
                        icon: Icons.star,
                        label: 'Graduação',
                        value: 'Máxima',
                        color: Colors.amber,
                      ),
                  ]),
                ),
              ),

              // Ações rápidas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: QuickActionsWidget(profile: profile),
                ),
              ),

              // Todas as modalidades matriculadas (se tiver mais de uma)
              if (profile.enrolledModalities.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: EnrolledModalitiesWidget(profile: profile),
                  ),
                ),

              // Informações adicionais
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildInfoSection(profile),
                ),
              ),

              // Histórico de graduações (usa modalidade matriculada se disponível, senão legado)
              if (_hasGraduationHistory(profile))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: GraduationHistoryWidget(
                      profile: profile,
                      martialArt: martialArt,
                    ),
                  ),
                ),

              // Espaço extra no final
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
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


  Widget _buildInfoSection(UserProfile profile) {
    return AppInfoCard(
      title: 'Informações',
      children: [
        AppInfoRow(
          icon: Icons.sports_martial_arts,
          label: 'Arte Marcial',
          value: profile.martialArt.name,
        ),
        if (profile.academyName != null && profile.academyName!.isNotEmpty)
          AppInfoRow(
            icon: Icons.home_work,
            label: 'Academia',
            value: profile.academyName!,
          ),
        if (profile.instructorName != null && profile.instructorName!.isNotEmpty)
          AppInfoRow(
            icon: Icons.person,
            label: 'Professor',
            value: profile.instructorName!,
          ),
        if (profile.weightCategory != null &&
            profile.weightCategory!.isNotEmpty)
          AppInfoRow(
            icon: Icons.monitor_weight,
            label: 'Categoria',
            value: profile.weightCategory!,
          ),
        if (profile.startDate != null)
          AppInfoRow(
            icon: Icons.calendar_today,
            label: 'Início',
            value: _formatDate(profile.startDate!),
          ),
      ],
    );
  }


  String _formatTrainingTime(Duration? duration) {
    if (duration == null) return '-';

    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years ano${years > 1 ? 's' : ''} ${months > 0 ? '$months m' : ''}';
    } else if (months > 0) {
      return '$months mês${months > 1 ? 'es' : ''}';
    } else {
      final days = duration.inDays;
      return '$days dia${days > 1 ? 's' : ''}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getBeltColor(Belt belt) {
    if (belt.color == Colors.white) {
      return AppColors.textSecondaryDark;
    }
    return belt.color;
  }

  /// Verifica se tem histórico de graduações (modalidade matriculada ou legado)
  bool _hasGraduationHistory(UserProfile profile) {
    if (profile.enrolledModalities.isNotEmpty) {
      return profile.enrolledModalities.first.graduationHistory.isNotEmpty;
    }
    return profile.graduationHistory.isNotEmpty;
  }


  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sair da conta'),
        content: const Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Limpa o ProfileService antes de fazer logout
              context.read<ProfileService>().clear();
              authViewModel.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
