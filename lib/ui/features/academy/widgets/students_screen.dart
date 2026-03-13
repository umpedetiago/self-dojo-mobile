import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/students_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de listagem de alunos da academia
class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userId = authViewModel.user.id;

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Primeiro obtém a academia
    return ChangeNotifierProvider(
      create: (ctx) => AcademyViewModel(
        academyRepository: ctx.read<AcademyRepository>(),
        profileRepository: ctx.read(),
        userId: userId,
      ),
      child: const _StudentsScreenLoader(),
    );
  }
}

class _StudentsScreenLoader extends StatelessWidget {
  const _StudentsScreenLoader();

  @override
  Widget build(BuildContext context) {
    final academyViewModel = context.watch<AcademyViewModel>();

    if (academyViewModel.isLoading) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (!academyViewModel.hasAcademy) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: Text(
              'Academia não encontrada',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
        ),
      );
    }

    // Cria o StudentsViewModel com o ID da academia
    return ChangeNotifierProvider(
      create: (ctx) => StudentsViewModel(
        studentsRepository: ctx.read<StudentsRepository>(),
        academyId: academyViewModel.academy.id,
      ),
      child: _StudentsContent(
        modalities: academyViewModel.academy.modalityTypes,
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
}

class _StudentsContent extends StatefulWidget {
  const _StudentsContent({required this.modalities});

  final List<MartialArtType> modalities;

  @override
  State<_StudentsContent> createState() => _StudentsContentState();
}

class _StudentsContentState extends State<_StudentsContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudentsViewModel>();

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchAndFilter(context, viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : viewModel.filteredStudents.isEmpty
                        ? _buildEmptyState(viewModel)
                        : _buildStudentsList(viewModel),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Expanded(
            child: Text(
              'Alunos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
      BuildContext context, StudentsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: viewModel.search,
            style: const TextStyle(color: AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'Buscar aluno...',
              hintStyle: TextStyle(color: AppColors.textTertiaryDark),
              prefixIcon: Icon(Icons.search, color: AppColors.textTertiaryDark),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textTertiaryDark),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          if (widget.modalities.length > 1)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'Todos',
                    isSelected: viewModel.filterModality == null,
                    onTap: () => viewModel.filterByModality(null),
                  ),
                  ...widget.modalities.map((type) {
                    final art = MartialArtsConfig.getByType(type);
                    return _buildFilterChip(
                      label: art.shortName,
                      isSelected: viewModel.filterModality == type,
                      color: art.primaryColor,
                      onTap: () => viewModel.filterByModality(type),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Count
          Row(
            children: [
              Text(
                '${viewModel.filteredStudents.length} aluno${viewModel.filteredStudents.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.2)
              : AppColors.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(StudentsViewModel viewModel) {
    final hasSearch = viewModel.searchQuery.isNotEmpty ||
        viewModel.filterModality != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'Nenhum aluno encontrado' : 'Nenhum aluno ainda',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Tente buscar com outros termos'
                  : 'Alunos aparecerão aqui\nquando forem aprovados',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(StudentsViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: viewModel.filteredStudents.length,
        itemBuilder: (context, index) {
          final student = viewModel.filteredStudents[index];
          return _StudentCard(student: student);
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final AcademyStudent student;

  @override
  Widget build(BuildContext context) {
    final modality = student.primaryModality;
    final belt = modality?.currentBelt;

    return GestureDetector(
      onTap: () {
        context.push('/academy/students/${student.memberId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: belt?.color.withValues(alpha: 0.3) ??
                AppColors.surfaceVariantDark.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(belt),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Graduação e modalidade
                    if (modality != null && belt != null)
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: belt.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${belt.name}${modality.degree > 0 ? ' ${modality.degree}º grau' : ''}',
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            ' • ${modality.martialArt.shortName}',
                            style: TextStyle(
                              color: modality.martialArt.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Aulas
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: AppColors.textTertiaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${student.totalClasses} aulas',
                          style: TextStyle(
                            color: AppColors.textTertiaryDark,
                            fontSize: 12,
                          ),
                        ),
                        
                      ],
                    ),
                  ],
                ),
              ),

              // Payment status indicator
              if (student.paymentStatus != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: student.isPaymentActive
                        ? AppColors.success
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic belt) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: belt?.color.withValues(alpha: 0.2) ??
            AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        image: student.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(student.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: student.photoUrl == null
          ? Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: belt?.color ?? AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

