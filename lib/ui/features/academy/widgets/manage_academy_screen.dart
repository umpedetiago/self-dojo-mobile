import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/navigation/app_navigation.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/ui/components/components.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/subscription.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de gerenciamento da academia (Dashboard do Owner)
class ManageAcademyScreen extends StatelessWidget {
  const ManageAcademyScreen({super.key, this.academyId});

  /// Quando informado, abre diretamente esta academia (usado no fluxo de seleção).
  final String? academyId;

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
        academyId: academyId,
      ),
      child: const _ManageAcademyContent(),
    );
  }
}

class _ManageAcademyContent extends StatefulWidget {
  const _ManageAcademyContent();

  @override
  State<_ManageAcademyContent> createState() => _ManageAcademyContentState();
}

class _ManageAcademyContentState extends State<_ManageAcademyContent> {
  int _academyCount = 1; // Inicia com 1 (a academia atual)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwnerAcademies();
    });
  }

  Future<void> _loadOwnerAcademies() async {
    final viewModel = context.read<AcademyViewModel>();
    if (!viewModel.hasAcademy) return;

    final authViewModel = context.read<AuthViewModel>();
    final academyRepository = context.read<AcademyRepository>();
    final ownerId = authViewModel.user.id;

    final result = await academyRepository.getOwnerAcademies(ownerId);
    result.fold(
      onSuccess: (academies) {
        if (mounted) {
          setState(() {
            _academyCount = academies.length;
          });
        }
      },
      onFailure: (_) {
        // Em caso de erro, mantém o valor padrão (1)
      },
    );
  }

  bool get _hasMultipleAcademies => _academyCount > 1;

  bool _canCreateNewAcademy(Academy academy) {
    // Verifica se o plano permite criar múltiplas academias
    // Por enquanto, assumimos que Enterprise permite múltiplas academias
    // ou que todos os planos permitem (pode ser ajustado conforme regra de negócio)
    final plan = academy.subscription?.plan;
    // Se já tem múltiplas academias, pode criar mais (já tem permissão)
    // Ou se o plano for Enterprise
    return _hasMultipleAcademies || plan == SubscriptionPlan.enterprise;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AcademyViewModel>();

    if (viewModel.isLoading) {
      return const AppLoadingScaffold();
    }

    // Se não tem academia, redireciona para criar
    if (!viewModel.hasAcademy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigation.goToCreateAcademy(context);
      });
      return const SizedBox.shrink();
    }

    final academy = viewModel.academy;

    return Scaffold(
      drawer: _buildDrawer(context, academy),
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
                  child: AppBannerCard(
                    icon: Icons.card_giftcard,
                    title: 'Período de Trial',
                    subtitle:
                        '${viewModel.trialDaysRemaining} dias restantes • Até 10 alunos',
                    actionLabel: 'Assinar',
                    onAction: () {
                      // TODO: ir para assinatura
                    },
                  ),
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
                    AppStatCard(
                      icon: Icons.people,
                      label: 'Alunos',
                      value: '${viewModel.studentCount}',
                      maxValue: viewModel.isOnTrial
                          ? '/ 10'
                          : '/ ${academy.subscription?.maxStudents ?? '∞'}',
                      color: AppColors.primary,
                      onTap: () => AppNavigation.pushToAcademyStudents(context),
                    ),
                    AppStatCard(
                      icon: Icons.sports_martial_arts,
                      label: 'Modalidades',
                      value: '${academy.modalities.length}',
                      maxValue: '/ ${academy.subscription?.maxModalities ?? '∞'}',
                      color: AppColors.secondary,
                      onTap: () => AppNavigation.pushToAcademyModalities(context),
                    ),
                    AppStatCard(
                      icon: Icons.school,
                      label: 'Professores',
                      value: '${academy.totalTeachers}',
                      maxValue: '/ ${academy.subscription?.maxTeachers ?? '∞'}',
                      color: AppColors.accent,
                      onTap: () => AppNavigation.pushToAcademyTeachers(context),
                    ),
                    AppStatCard(
                      icon: Icons.pending_actions,
                      label: 'Solicitações',
                      value: '${viewModel.pendingRequestsCount}',
                      color: Colors.orange,
                      onTap: () async {
                        await AppNavigation.pushToAcademyRequests(context);
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
                      const AppSectionTitle(
                        title: 'Gerenciamento',
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      AppMenuItemCard(
                        icon: Icons.sports_martial_arts,
                        title: 'Modalidades',
                        subtitle: 'Gerenciar artes marciais e graduações',
                        onTap: () => AppNavigation.pushToAcademyModalities(context),
                      ),
                      AppMenuItemCard(
                        icon: Icons.people,
                        title: 'Alunos',
                        subtitle: 'Ver e gerenciar alunos',
                        onTap: () => AppNavigation.pushToAcademyStudents(context),
                      ),
                      AppMenuItemCard(
                        icon: Icons.person_add,
                        title: 'Solicitações',
                        subtitle: 'Aprovar novos alunos',
                        onTap: () async {
                          await AppNavigation.pushToAcademyRequests(context);
                          viewModel.refreshPendingRequestsCount();
                        },
                      ),
                      AppMenuItemCard(
                        icon: Icons.school,
                        title: 'Equipe',
                        subtitle: 'Professores e instrutores',
                        onTap: () => AppNavigation.pushToAcademyTeachers(context),
                      ),
                      AppMenuItemCard(
                        icon: Icons.schedule,
                        title: 'Horários de Aulas',
                        subtitle: 'Gerenciar horários e disponibilizar check-in',
                        onTap: () => AppNavigation.pushToAcademySchedules(context),
                      ),
                      AppMenuItemCard(
                        icon: Icons.person,
                        title: 'Editar Perfil',
                        subtitle: 'Dados do owner',
                        onTap: () => AppNavigation.pushToEditProfile(context),
                      ),
                      AppMenuItemCard(
                        icon: Icons.edit,
                        title: 'Editar Academia',
                        subtitle: 'Informações da academia',
                        onTap: () => AppNavigation.pushToEditAcademy(
                          context,
                          academyId: academy.id,
                        ),
                      ),
                      AppMenuItemCard(
                        icon: Icons.credit_card,
                        title: 'Assinatura',
                        subtitle: academy.subscription?.isTrial == true
                            ? 'Trial - ${viewModel.trialDaysRemaining} dias restantes'
                            : 'Gerenciar plano',
                        onTap: () => AppNavigation.pushToAcademySubscription(context),
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
              // Botão de voltar apenas se houver múltiplas academias
              if (_hasMultipleAcademies)
                IconButton(
                  onPressed: () => AppNavigation.goToSelectAcademy(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimaryDark,
                  ),
                )
              else
                // Botão de menu (drawer) quando há apenas uma academia
                Builder(
                  builder: (builderContext) => IconButton(
                    onPressed: () => Scaffold.of(builderContext).openDrawer(),
                    icon: const Icon(
                      Icons.menu,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => AppNavigation.pushToEditAcademy(
                  context,
                  academyId: academy.id,
                ),
                icon: const Icon(
                  Icons.settings,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              IconButton(
                onPressed: () => AppNavigation.pushToEditProfile(context),
                icon: const Icon(
                  Icons.person,
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


  Widget _buildDrawer(BuildContext context, Academy currentAcademy) {
    final canCreateNew = _canCreateNewAcademy(currentAcademy);

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header do drawer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo da academia
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          image: currentAcademy.logoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(currentAcademy.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: currentAcademy.logoUrl == null
                            ? const Icon(
                                Icons.business,
                                color: AppColors.primary,
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentAcademy.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Academia Atual',
                              style: TextStyle(
                                fontSize: 12,
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
            ),

            // Opções do menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  AppMenuItemCard(
                    icon: Icons.edit,
                    title: 'Editar Academia',
                    subtitle: 'Informações da academia',
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushToEditAcademy(
                        context,
                        academyId: currentAcademy.id,
                      );
                    },
                  ),
                  AppMenuItemCard(
                    icon: Icons.person,
                    title: 'Editar Perfil',
                    subtitle: 'Dados do owner',
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushToEditProfile(context);
                    },
                  ),
                  if (canCreateNew)
                    AppMenuItemCard(
                      icon: Icons.add_business,
                      title: 'Criar Nova Academia',
                      subtitle: 'Adicionar uma nova academia',
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigation.goToCreateAcademy(context);
                      },
                    ),
                  if (_hasMultipleAcademies)
                    AppMenuItemCard(
                      icon: Icons.business,
                      title: 'Minhas Academias',
                      subtitle: 'Ver todas as academias',
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigation.goToSelectAcademy(context);
                      },
                    ),
                  const AppDivider(
                    height: 32,
                    indent: 20,
                    endIndent: 20,
                  ),
                  AppMenuItemCard(
                    icon: Icons.home,
                    title: 'Voltar para Home',
                    subtitle: 'Tela inicial',
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.goToHome(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

