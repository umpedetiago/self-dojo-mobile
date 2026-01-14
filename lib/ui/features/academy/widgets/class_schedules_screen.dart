import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart' as martial_arts;
import 'package:self_dojo_mobile/ui/features/academy/view_models/class_schedule_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de gerenciamento de horários de aulas
class ClassSchedulesScreen extends StatelessWidget {
  const ClassSchedulesScreen({super.key});

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
      child: const _ClassSchedulesWrapper(),
    );
  }
}

class _ClassSchedulesWrapper extends StatelessWidget {
  const _ClassSchedulesWrapper();

  @override
  Widget build(BuildContext context) {
    final academyViewModel = context.watch<AcademyViewModel>();
    final academyId = academyViewModel.academy.id;

    if (academyId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => ClassScheduleViewModel(
        classScheduleRepository: ctx.read<ClassScheduleRepository>(),
        academyId: academyId,
      )..loadSchedules(),
      child: const _ClassSchedulesContent(),
    );
  }
}

class _ClassSchedulesContent extends StatelessWidget {
  const _ClassSchedulesContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ClassScheduleViewModel>();
    final academyViewModel = context.watch<AcademyViewModel>();
    final academy = academyViewModel.academy;

    if (viewModel.isLoading && viewModel.schedules.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final schedulesByDay = viewModel.schedulesByDay;

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: schedulesByDay.isEmpty
                    ? _buildEmptyState(context, viewModel, academy)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: 7, // 7 dias da semana
                        itemBuilder: (context, index) {
                          final dayOfWeek = index;
                          final schedules = schedulesByDay[dayOfWeek] ?? [];
                          if (schedules.isEmpty) return const SizedBox.shrink();
                          return _buildDaySection(context, dayOfWeek, schedules, viewModel);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateScheduleDialog(context, viewModel, academy),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Horário',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
              'Horários de Aulas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ClassScheduleViewModel viewModel,
    Academy academy,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum horário cadastrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie horários de aulas para disponibilizar o check-in para os alunos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    int dayOfWeek,
    List<ClassSchedule> schedules,
    ClassScheduleViewModel viewModel,
  ) {
    final dayName = _getDayName(dayOfWeek);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            dayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ),
        ...schedules.map((schedule) => _buildScheduleCard(
          context,
          schedule,
          viewModel,
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    ClassSchedule schedule,
    ClassScheduleViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: schedule.isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.textTertiaryDark.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.timeRange,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    if (schedule.modalityType != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        martial_arts.MartialArtsConfig.getByType(schedule.modalityType!).name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                    if (schedule.classType != 'regular') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          schedule.classType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!schedule.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiaryDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Inativo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondaryDark,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditScheduleDialog(context, schedule, viewModel);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(context, schedule, viewModel);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (schedule.instructorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.instructorName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ],
          if (schedule.maxStudents != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  'Máximo: ${schedule.maxStudents} alunos',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    return days[dayOfWeek];
  }

  void _showCreateScheduleDialog(
    BuildContext context,
    ClassScheduleViewModel viewModel,
    Academy academy,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ScheduleFormDialog(
        academy: academy,
        onSave: (schedule) async {
          // Este callback será chamado múltiplas vezes (uma para cada dia)
          // Mas vamos criar todos os horários de uma vez no método _save
          // Então aqui só precisamos fechar o dialog após o primeiro
        },
        onSaveMultiple: (schedules) async {
          // Cria todos os horários
          int successCount = 0;
          String? errorMessage;
          
          for (final schedule in schedules) {
            final result = await viewModel.createSchedule(schedule);
            result.fold(
              onSuccess: (_) => successCount++,
              onFailure: (failure) => errorMessage = failure.message,
            );
          }
          
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            
            if (errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao criar alguns horários: $errorMessage'),
                  backgroundColor: AppColors.error,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    successCount == 1
                        ? 'Horário criado com sucesso!'
                        : '$successCount horários criados com sucesso!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditScheduleDialog(
    BuildContext context,
    ClassSchedule schedule,
    ClassScheduleViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ScheduleFormDialog(
        academy: null, // Não precisa para edição
        schedule: schedule,
        onSave: (updatedSchedule) async {
          final result = await viewModel.updateSchedule(updatedSchedule);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            result.fold(
              onSuccess: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Horário atualizado com sucesso!'),
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
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    ClassSchedule schedule,
    ClassScheduleViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 12),
            Text(
              'Confirmar Exclusão',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o horário ${schedule.timeRange}?',
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
              final result = await viewModel.deleteSchedule(schedule.id);
              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Horário excluído com sucesso!'),
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
              backgroundColor: AppColors.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
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

class _ScheduleFormDialog extends StatefulWidget {
  const _ScheduleFormDialog({
    required this.academy,
    this.schedule,
    required this.onSave,
    this.onSaveMultiple,
  });

  final Academy? academy;
  final ClassSchedule? schedule;
  final ValueChanged<ClassSchedule> onSave;
  final ValueChanged<List<ClassSchedule>>? onSaveMultiple;

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  late Set<int> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _modalityId;
  String _classType = 'regular';
  String? _instructorId;
  int? _maxStudents;
  bool _isActive = true;
  String? _notes;

  final _formKey = GlobalKey<FormState>();
  final _maxStudentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      final schedule = widget.schedule!;
      // Na edição, mostra apenas o dia atual
      _selectedDays = {schedule.dayOfWeek};
      _startTime = TimeOfDay.fromDateTime(schedule.startTime);
      _endTime = TimeOfDay.fromDateTime(schedule.endTime);
      _modalityId = schedule.modalityId;
      _classType = schedule.classType;
      _instructorId = schedule.instructorId;
      _maxStudents = schedule.maxStudents;
      _isActive = schedule.isActive;
      _notes = schedule.notes;
      if (_maxStudents != null) {
        _maxStudentsController.text = _maxStudents.toString();
      }
    } else {
      // Na criação, começa com o dia atual selecionado
      _selectedDays = {DateTime.now().weekday % 7};
      _startTime = const TimeOfDay(hour: 19, minute: 0);
      _endTime = const TimeOfDay(hour: 20, minute: 30);
    }
  }

  @override
  void dispose() {
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academy = widget.academy;
    final isEditing = widget.schedule != null;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Horário' : 'Novo Horário',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dia da semana
                      _buildLabel(
                        isEditing ? 'Dia da Semana' : 'Dias da Semana (selecione múltiplos)',
                      ),
                      const SizedBox(height: 8),
                      _buildDaySelector(isEditing: isEditing),
                      if (!isEditing && _selectedDays.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selecione pelo menos um dia',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Horário
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeField(
                              label: 'Início',
                              time: _startTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (picked != null) {
                                  setState(() => _startTime = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeField(
                              label: 'Fim',
                              time: _endTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (picked != null) {
                                  setState(() => _endTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Modalidade (se houver modalidades)
                      if (academy != null && academy.modalities.isNotEmpty) ...[
                        _buildLabel('Modalidade (opcional)'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _modalityId,
                          decoration: _inputDecoration(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todas as modalidades'),
                            ),
                            ...academy.modalities.map((m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.martialArt.name),
                                )),
                          ],
                          onChanged: (value) => setState(() => _modalityId = value),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Tipo de aula
                      _buildLabel('Tipo de Aula'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _classType,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(value: 'regular', child: Text('Regular')),
                          DropdownMenuItem(value: 'sparring', child: Text('Sparring')),
                          DropdownMenuItem(value: 'open_mat', child: Text('Open Mat')),
                          DropdownMenuItem(value: 'kids', child: Text('Kids')),
                          DropdownMenuItem(value: 'competition', child: Text('Competição')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _classType = value);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Máximo de alunos
                      _buildLabel('Máximo de Alunos (opcional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _maxStudentsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration(hint: 'Sem limite'),
                        onChanged: (value) {
                          _maxStudents = value.isEmpty
                              ? null
                              : int.tryParse(value);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Ativo
                      Row(
                        children: [
                          Checkbox(
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value ?? true),
                            activeColor: AppColors.primary,
                          ),
                          const Text(
                            'Horário ativo',
                            style: TextStyle(color: AppColors.textPrimaryDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
      ),
    );
  }

  Widget _buildDaySelector({required bool isEditing}) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            if (isEditing) {
              // Na edição, permite apenas um dia
              setState(() => _selectedDays = {index});
            } else {
              // Na criação, permite múltiplos dias
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(index);
                } else {
                  _selectedDays.add(index);
                }
              });
            }
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceVariantDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondaryDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textTertiaryDark.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.textSecondaryDark,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textTertiaryDark),
      filled: true,
      fillColor: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textTertiaryDark.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textTertiaryDark.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Valida se pelo menos um dia foi selecionado (apenas na criação)
    if (widget.schedule == null && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia da semana'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      2000,
      1,
      1,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      2000,
      1,
      1,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O horário de fim deve ser após o horário de início'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Se está editando, salva apenas o horário atual
    if (widget.schedule != null) {
      final schedule = ClassSchedule(
        id: widget.schedule!.id,
        academyId: widget.schedule!.academyId,
        modalityId: _modalityId,
        dayOfWeek: _selectedDays.first,
        startTime: startDateTime,
        endTime: endDateTime,
        classType: _classType,
        instructorId: _instructorId,
        isActive: _isActive,
        maxStudents: _maxStudents,
        notes: _notes,
      );
      widget.onSave(schedule);
      return;
    }

    // Se está criando, cria um horário para cada dia selecionado
    final academyId = widget.academy!.id;
    
    // Cria lista de horários para todos os dias selecionados
    final schedules = _selectedDays.map((day) {
      return ClassSchedule(
        id: '',
        academyId: academyId,
        modalityId: _modalityId,
        dayOfWeek: day,
        startTime: startDateTime,
        endTime: endDateTime,
        classType: _classType,
        instructorId: _instructorId,
        isActive: _isActive,
        maxStudents: _maxStudents,
        notes: _notes,
      );
    }).toList();

    // Se há callback para múltiplos horários, usa ele; senão, usa o callback único
    if (widget.onSaveMultiple != null) {
      widget.onSaveMultiple!(schedules);
    } else {
      // Fallback: cria um por um (comportamento antigo)
      for (final schedule in schedules) {
        widget.onSave(schedule);
      }
    }
  }
}

