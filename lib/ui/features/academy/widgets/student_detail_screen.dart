import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/students_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de detalhes do aluno para edição de graduação e check-in
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({
    super.key,
    required this.memberId,
  });

  final String memberId;

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
        profileRepository: ctx.read(),
        userId: userId,
      ),
      child: _StudentDetailLoader(memberId: memberId),
    );
  }
}

class _StudentDetailLoader extends StatelessWidget {
  const _StudentDetailLoader({required this.memberId});

  final String memberId;

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

    return ChangeNotifierProvider(
      create: (ctx) => StudentsViewModel(
        studentsRepository: ctx.read<StudentsRepository>(),
        academyId: academyViewModel.academy.id,
      ),
      child: _StudentDetailContent(
        memberId: memberId,
        academy: academyViewModel.academy,
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

class _StudentDetailContent extends StatelessWidget {
  const _StudentDetailContent({
    required this.memberId,
    required this.academy,
  });

  final String memberId;
  final Academy academy;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudentsViewModel>();

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

    final student = viewModel.getStudent(memberId);

    if (student == null) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, null),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Aluno não encontrado',
                      style: TextStyle(color: AppColors.textPrimaryDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, student),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentHeader(student),
                      const SizedBox(height: 24),
                      _buildInfoCard(student),
                      const SizedBox(height: 24),
                      ...student.modalities.map((modality) {
                        return _ModalitySection(
                          student: student,
                          modality: modality,
                          viewModel: viewModel,
                        );
                      }),
                      // Botão para adicionar nova modalidade
                      _buildAddModalityButton(context, student, viewModel),
                    ],
                  ),
                ),
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

  Widget _buildAppBar(BuildContext context, AcademyStudent? student) {
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
          Expanded(
            child: Text(
              student?.name ?? 'Detalhes do Aluno',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(AcademyStudent student) {
    final modality = student.primaryModality;
    final belt = modality?.currentBelt;

    return Row(
      children: [
        // Avatar grande
        Container(
          width: 80,
          height: 80,
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
            border: Border.all(
              color: belt?.color.withValues(alpha: 0.5) ??
                  AppColors.primary.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
          child: student.photoUrl == null
              ? Center(
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: belt?.color ?? AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                student.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusBadge(student),
                  if (student.paymentStatus != null) ...[
                    const SizedBox(width: 8),
                    _buildPaymentBadge(student),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AcademyStudent student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: student.isApproved
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        student.isApproved ? 'Ativo' : 'Pendente',
        style: TextStyle(
          color: student.isApproved ? AppColors.success : AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(AcademyStudent student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: student.isPaymentActive
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        student.isPaymentActive ? 'Pgto. OK' : 'Pgto. Pendente',
        style: TextStyle(
          color: student.isPaymentActive ? AppColors.primary : AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(AcademyStudent student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Membro desde',
            _formatDate(student.joinedAt),
          ),
          const Divider(color: AppColors.surfaceVariantDark, height: 24),
          _buildInfoRow(
            Icons.fitness_center,
            'Total de aulas',
            '${student.totalClasses}',
          ),
          const Divider(color: AppColors.surfaceVariantDark, height: 24),
          _buildInfoRow(
            Icons.sports_martial_arts,
            'Modalidades',
            '${student.modalities.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textTertiaryDark),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildAddModalityButton(
    BuildContext context,
    AcademyStudent student,
    StudentsViewModel viewModel,
  ) {
    // Filtra modalidades que o aluno ainda não está matriculado
    final enrolledTypes = student.modalities.map((m) => m.type).toSet();
    final availableModalities = academy.modalities
        .where((m) => !enrolledTypes.contains(m.type) && m.isActive)
        .toList();

    if (availableModalities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          _showAddModalityDialog(context, student, viewModel, availableModalities);
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Adicionar Modalidade'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showAddModalityDialog(
    BuildContext context,
    AcademyStudent student,
    StudentsViewModel viewModel,
    List<AcademyModality> availableModalities,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => _AddModalitySheet(
        student: student,
        viewModel: viewModel,
        availableModalities: availableModalities,
      ),
    );
  }
}

/// Bottom sheet para adicionar nova modalidade
class _AddModalitySheet extends StatefulWidget {
  const _AddModalitySheet({
    required this.student,
    required this.viewModel,
    required this.availableModalities,
  });

  final AcademyStudent student;
  final StudentsViewModel viewModel;
  final List<AcademyModality> availableModalities;

  @override
  State<_AddModalitySheet> createState() => _AddModalitySheetState();
}

class _AddModalitySheetState extends State<_AddModalitySheet> {
  AcademyModality? _selectedModality;
  String? _selectedBeltId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.availableModalities.isNotEmpty) {
      _selectedModality = widget.availableModalities.first;
      final art = MartialArtsConfig.getByType(_selectedModality!.type);
      _selectedBeltId = art.belts?.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.sports_martial_arts,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adicionar Modalidade',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      widget.student.name,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon:
                    const Icon(Icons.close, color: AppColors.textSecondaryDark),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Seleção de modalidade
          const Text(
            'Modalidade',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),

          // Lista de modalidades disponíveis
          ...widget.availableModalities.map((modality) {
            final art = MartialArtsConfig.getByType(modality.type);
            final isSelected = _selectedModality == modality;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedModality = modality;
                  _selectedBeltId = art.belts?.first.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? art.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? art.primaryColor
                        : AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(art.icon, color: art.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      art.name,
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: art.primaryColor, size: 20),
                  ],
                ),
              ),
            );
          }),

          // Seleção de graduação
          if (_selectedModality != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Graduação Inicial',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MartialArtsConfig.getByType(_selectedModality!.type)
                    .belts
                    ?.length ?? 0,
                itemBuilder: (context, index) {
                  final art =
                      MartialArtsConfig.getByType(_selectedModality!.type);
                  final belt = art.belts?[index];
                  final isSelectedBelt = _selectedBeltId == belt?.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBeltId = belt?.id;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelectedBelt
                            ? belt?.color.withValues(alpha: 0.2) ?? Colors.transparent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelectedBelt
                              ? belt?.color ?? Colors.transparent
                              : AppColors.surfaceVariantDark
                                  .withValues(alpha: 0.5),
                          width: isSelectedBelt ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 10,
                            decoration: BoxDecoration(
                              color: belt?.color ?? Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                              border: belt?.color == Colors.white
                                  ? Border.all(color: Colors.grey.shade400)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            belt?.name ?? '',
                            style: TextStyle(
                              color: isSelectedBelt
                                  ? (belt?.color.computeLuminance() ?? 0.0) > 0.5
                                      ? Colors.black87
                                      : AppColors.textPrimaryDark
                                  : AppColors.textSecondaryDark,
                              fontWeight: isSelectedBelt
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryDark,
                    side: BorderSide(
                      color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedModality != null && _selectedBeltId != null && !_isLoading
                      ? _enrollInModality
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Matricular'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _enrollInModality() async {
    if (_selectedModality == null || _selectedBeltId == null) return;

    setState(() => _isLoading = true);

    final result = await widget.viewModel.enrollInModality(
      EnrollModalityParams(
        memberId: widget.student.memberId,
        academyModalityId: _selectedModality!.id,
        martialArtType: _selectedModality!.type.name,
        initialBeltId: _selectedBeltId!,
      ),
    );

    if (mounted) {
      Navigator.pop(context);

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.student.name} matriculado em ${_selectedModality!.martialArt.name}!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        onFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    }
  }
}

/// Seção de modalidade com graduação e ações
class _ModalitySection extends StatelessWidget {
  const _ModalitySection({
    required this.student,
    required this.modality,
    required this.viewModel,
  });

  final AcademyStudent student;
  final StudentModalityInfo modality;
  final StudentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final martialArt = modality.martialArt;
    final belt = modality.currentBelt;
    final nextBelt = modality.nextBelt;

    // Verifica se pode promover grau na mesma faixa ou precisa mudar de faixa
    final canPromoteDegree =
        belt != null && modality.degree < belt.maxDegrees;
    final canPromoteBelt = !canPromoteDegree && nextBelt != null;
    final canPromote = canPromoteDegree || canPromoteBelt;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: martialArt.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da modalidade
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: martialArt.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: martialArt.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    martialArt.icon,
                    color: martialArt.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    martialArt.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Graduação atual
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Graduação Atual',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (belt != null)
                  _buildCurrentBeltDisplay(belt, modality),
                const SizedBox(height: 16),

                // Progresso
                _buildProgressSection(modality, belt, nextBelt, canPromoteDegree),
                const SizedBox(height: 16),

                // Estatísticas
                _buildStatsRow(modality),
              ],
            ),
          ),

          // Ações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showEditClassesDialog(context, modality);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar Aulas'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimaryDark,
                          side: BorderSide(
                            color: AppColors.surfaceVariantDark
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canPromote
                            ? () {
                                _showPromoteDialog(
                                  context,
                                  modality,
                                  belt!,
                                  nextBelt,
                                  canPromoteDegree,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.military_tech, size: 18),
                        label: Text(canPromoteDegree ? 'Promover Grau' : 'Promover Faixa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor:
                              AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showCheckInDialog(context, modality);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Registrar Check-in'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Histórico de graduações
          if (modality.graduationHistory.isNotEmpty)
            _buildGraduationHistory(modality),
        ],
      ),
    );
  }

  Widget _buildCurrentBeltDisplay(Belt belt, StudentModalityInfo modality) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: belt.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: belt.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Faixa visual
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: belt.color,
              borderRadius: BorderRadius.circular(2),
              border: belt.color == Colors.white
                  ? Border.all(color: Colors.grey.shade400)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  belt.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                if (modality.degree > 0)
                  Text(
                    '${modality.degree}º grau',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
              ],
            ),
          ),
          if (modality.promotionDate != null)
            Text(
              'Desde ${_formatShortDate(modality.promotionDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiaryDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    StudentModalityInfo modality,
    Belt? currentBelt,
    Belt? nextBelt,
    bool canPromoteDegree,
  ) {
    // Se não pode promover grau nem faixa, graduação máxima alcançada
    if (!canPromoteDegree && nextBelt == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text(
              'Graduação máxima alcançada!',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Se é promoção de grau, mostra informação diferente
    if (canPromoteDegree && currentBelt != null) {
      final nextDegree = modality.degree + 1;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: currentBelt.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_upward, color: currentBelt.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximo: $nextDegreeº grau',
                    style: TextStyle(
                      color: currentBelt.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Grau atual: ${modality.degree == 0 ? "Sem grau" : "${modality.degree}º grau"} • Máximo: ${currentBelt.maxDegrees}º',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Promoção de faixa - mostra progresso de aulas
    final targetBelt = nextBelt!;
    final progress = modality.classesAtCurrentBelt /
        (targetBelt.minClassesForPromotion > 0
            ? targetBelt.minClassesForPromotion
            : 1);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso para ${targetBelt.name}',
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            Text(
              '${modality.classesAtCurrentBelt}/${targetBelt.minClassesForPromotion} aulas',
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              clampedProgress >= 1.0 ? AppColors.success : targetBelt.color,
            ),
            minHeight: 8,
          ),
        ),
        if (modality.classesUntilPromotion > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Faltam ${modality.classesUntilPromotion} aulas',
              style: TextStyle(
                color: AppColors.textTertiaryDark,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(StudentModalityInfo modality) {
    return Row(
      children: [
        _buildStatItem(
          Icons.fitness_center,
          '${modality.totalClasses}',
          'Total',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.calendar_month,
          _formatTrainingTime(modality.trainingTime),
          'Treino',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantDark.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiaryDark),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textTertiaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraduationHistory(StudentModalityInfo modality) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: const Text(
        'Histórico de Graduações',
        style: TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
      ),
      iconColor: AppColors.textTertiaryDark,
      collapsedIconColor: AppColors.textTertiaryDark,
      children: modality.graduationHistory.reversed.map((history) {
        final belt = modality.martialArt.getBeltById(history.beltId);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantDark.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: belt?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${belt?.name ?? 'Faixa'}${history.degree > 0 ? ' - ${history.degree}º grau' : ''}',
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (history.notes != null && history.notes!.isNotEmpty)
                      Text(
                        history.notes!,
                        style: TextStyle(
                          color: AppColors.textTertiaryDark,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _formatShortDate(history.date),
                style: TextStyle(
                  color: AppColors.textTertiaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showEditClassesDialog(
      BuildContext context, StudentModalityInfo modality) {
    final totalController =
        TextEditingController(text: modality.totalClasses.toString());
    final currentController =
        TextEditingController(text: modality.classesAtCurrentBelt.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar Aulas',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Total de Aulas',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Aulas na Faixa Atual',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final total = int.tryParse(totalController.text) ?? 0;
              final current = int.tryParse(currentController.text) ?? 0;

              Navigator.pop(dialogContext);

              final result = await viewModel.updateStudentClasses.execute(
                UpdateClassesParams(
                  studentModalityId: modality.id,
                  totalClasses: total,
                  classesAtCurrentBelt: current,
                ),
              );

              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aulas atualizadas com sucesso!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  onFailure: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Dispose controllers quando o dialog fechar
    // Note: Como estamos em um StatelessWidget, o dispose precisa ser manual
  }

  void _showPromoteDialog(
    BuildContext context,
    StudentModalityInfo modality,
    Belt currentBelt,
    Belt? nextBelt,
    bool isDegreePromotion,
  ) {
    final notesController = TextEditingController();
    // Se é promoção de grau, o próximo grau é o atual + 1
    // Se é promoção de faixa, começa do grau 0
    int selectedDegree = isDegreePromotion ? modality.degree + 1 : 0;

    // A faixa alvo é a atual (para promoção de grau) ou a próxima (para promoção de faixa)
    final targetBelt = isDegreePromotion ? currentBelt : nextBelt!;

    // Título e descrição baseados no tipo de promoção
    final String promotionTitle =
        isDegreePromotion ? 'Promover Grau' : 'Promover Faixa';
    final String promotionDescription = isDegreePromotion
        ? 'Promover para $selectedDegreeº grau da ${currentBelt.name}'
        : 'Promover para ${nextBelt!.name}';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.military_tech, color: targetBelt.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  promotionTitle,
                  style: const TextStyle(color: AppColors.textPrimaryDark),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promotionDescription,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Seletor de grau (apenas para promoção de faixa, se a nova faixa tiver graus)
              if (!isDegreePromotion && targetBelt.maxDegrees > 0) ...[
                const Text(
                  'Grau inicial',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(targetBelt.maxDegrees + 1, (index) {
                    return ChoiceChip(
                      label: Text(index == 0 ? 'Sem grau' : '$indexº'),
                      selected: selectedDegree == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedDegree = index);
                        }
                      },
                      selectedColor: targetBelt.color.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: selectedDegree == index
                            ? targetBelt.color
                            : AppColors.textSecondaryDark,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Notas
              TextField(
                controller: notesController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Observações (opcional)',
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final result = await viewModel.promoteStudent.execute(
                  PromoteStudentParams(
                    studentModalityId: modality.id,
                    newBeltId: targetBelt.id,
                    degree: selectedDegree,
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  ),
                );

                if (context.mounted) {
                  result.fold(
                    onSuccess: (_) {
                      final successMessage = isDegreePromotion
                          ? '${student.name} promovido para $selectedDegreeº grau!'
                          : '${student.name} promovido para ${targetBelt.name}!';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(successMessage),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    onFailure: (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: targetBelt.color,
                foregroundColor: targetBelt.color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
              child: const Text('Confirmar Promoção'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckInDialog(BuildContext context, StudentModalityInfo modality) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text(
              'Registrar Check-in',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ],
        ),
        content: Text(
          'Registrar presença de ${student.name} na aula de hoje?',
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Incrementa aulas
              final result = await viewModel.updateStudentClasses.execute(
                UpdateClassesParams(
                  studentModalityId: modality.id,
                  totalClasses: modality.totalClasses + 1,
                  classesAtCurrentBelt: modality.classesAtCurrentBelt + 1,
                ),
              );

              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Check-in registrado com sucesso!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  onFailure: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  String _formatTrainingTime(Duration duration) {
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;

    if (years > 0) {
      return '${years}a ${months}m';
    } else if (months > 0) {
      return '${months}m';
    } else {
      return '${duration.inDays}d';
    }
  }
}

