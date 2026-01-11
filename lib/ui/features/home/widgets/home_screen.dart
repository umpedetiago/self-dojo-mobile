import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/belt_display.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/profile_header.dart';
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

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

              // Faixa atual
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BeltDisplay(
                    martialArt: martialArt,
                    belt: currentBelt,
                    degree: profile.graduation?.degree ?? 0,
                    graduation: profile.graduation,
                  ),
                ),
              ),

              // Cards de estatísticas
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      value: '${profile.totalClasses}',
                      color: AppColors.primary,
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
                  child: _buildQuickActions(context, profile),
                ),
              ),

              // Informações adicionais
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildInfoSection(profile),
                ),
              ),

              // Histórico de graduações
              if (profile.graduationHistory.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildGraduationHistory(profile, martialArt),
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

  Widget _buildQuickActions(BuildContext context, UserProfile profile) {
    // Verifica se tem academia (owner ou tem academyId)
    final hasAcademy = profile.isOwner || (profile.academyId != null && profile.academyId!.isNotEmpty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.business,
              label: hasAcademy ? 'Minha Academia' : 'Criar Academia',
              color: AppColors.primary,
              onTap: () {
                // Sempre tenta ir para manage primeiro, se não tiver academia redireciona
                context.push('/academy/manage');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.qr_code_scanner,
              label: 'Check-in',
              color: AppColors.secondary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check-in em desenvolvimento'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(UserProfile profile) {
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
          const Text(
            'Informações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.sports_martial_arts, 'Arte Marcial',
              profile.martialArt.name),
          if (profile.academyName != null && profile.academyName!.isNotEmpty)
            _buildInfoRow(Icons.home_work, 'Academia', profile.academyName!),
          if (profile.instructorName != null && profile.instructorName!.isNotEmpty)
            _buildInfoRow(Icons.person, 'Professor', profile.instructorName!),
          if (profile.weightCategory != null &&
              profile.weightCategory!.isNotEmpty)
            _buildInfoRow(Icons.monitor_weight, 'Categoria',
                profile.weightCategory!),
          if (profile.startDate != null)
            _buildInfoRow(Icons.calendar_today, 'Início',
                _formatDate(profile.startDate!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraduationHistory(UserProfile profile, MartialArt martialArt) {
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
          const Text(
            'Histórico de Graduações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...profile.graduationHistory.reversed.take(5).map((history) {
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
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(history.date),
                          style: TextStyle(
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
                        style: const TextStyle(
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
