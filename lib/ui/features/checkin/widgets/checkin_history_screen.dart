import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart' as martial_arts;
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/checkin/view_models/checkin_history_viewmodel.dart';

/// Tela de histórico de check-ins
class CheckInHistoryScreen extends StatelessWidget {
  const CheckInHistoryScreen({super.key});

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
      create: (ctx) => CheckInHistoryViewModel(
        studentsRepository: ctx.read<StudentsRepository>(),
        supabaseService: ctx.read<SupabaseService>(),
        userId: userId,
      )..loadHistory(),
      child: const _CheckInHistoryContent(),
    );
  }
}

class _CheckInHistoryContent extends StatelessWidget {
  const _CheckInHistoryContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CheckInHistoryViewModel>();

    if (viewModel.isLoading && viewModel.checkIns.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (viewModel.error != null) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final checkIns = viewModel.checkIns;
    final modalities = viewModel.modalities;

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              if (modalities.length > 1) _buildFilterBar(context, viewModel, modalities),
              Expanded(
                child: checkIns.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.loadHistory(
                          modalityId: viewModel.selectedModalityId,
                        ),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: checkIns.length,
                          itemBuilder: (context, index) {
                            final checkIn = checkIns[index];
                            return _buildCheckInCard(checkIn);
                          },
                        ),
                      ),
              ),
            ],
          ),
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
              'Histórico de Check-ins',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.read<CheckInHistoryViewModel>().loadHistory(
              modalityId: context.read<CheckInHistoryViewModel>().selectedModalityId,
            ),
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    CheckInHistoryViewModel viewModel,
    List<StudentModalityInfo> modalities,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textTertiaryDark.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 20,
            color: AppColors.textSecondaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: viewModel.selectedModalityId,
                isExpanded: true,
                hint: const Text(
                  'Todas as modalidades',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todas as modalidades'),
                  ),
                  ...modalities.map((m) => DropdownMenuItem<String>(
                        value: m.id,
                        child: Text(
                          martial_arts.MartialArtsConfig.getByType(m.type).name,
                        ),
                      )),
                ],
                onChanged: (value) {
                  viewModel.filterByModality(value);
                },
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                ),
                dropdownColor: AppColors.surfaceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum check-in registrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus check-ins aparecerão aqui',
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

  Widget _buildCheckInCard(CheckInHistoryItem checkIn) {
    final date = checkIn.checkedInAt;
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
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
                      _formatDateTime(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getModalityName(checkIn),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    if (checkIn.scheduleStartTime != null && checkIn.scheduleEndTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textSecondaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatScheduleTime(checkIn),
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
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Hoje',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (checkIn.classType != null && checkIn.classType != 'regular') ...[
            const SizedBox(height: 8),
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
                checkIn.classType!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (checkIn.notes != null && checkIn.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              checkIn.notes!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (checkInDate == today) {
      dateStr = 'Hoje';
    } else if (checkInDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Ontem';
    } else {
      final daysDiff = today.difference(checkInDate).inDays;
      if (daysDiff < 7) {
        dateStr = _getDayName(date.weekday);
      } else {
        dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }

    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr às $timeStr';
  }

  String _getDayName(int weekday) {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    return days[weekday % 7];
  }

  String _getModalityName(CheckInHistoryItem checkIn) {
    // Se tem modalityType do horário, usa ele; senão usa a modalidade do aluno
    if (checkIn.modalityType != null) {
      try {
        final type = martial_arts.MartialArtType.values.firstWhere(
          (t) => t.name == checkIn.modalityType,
        );
        return martial_arts.MartialArtsConfig.getByType(type).name;
      } catch (_) {
        // Fallback para modalidade do aluno
      }
    }
    return martial_arts.MartialArtsConfig
        .getByType(checkIn.modality.type)
        .name;
  }

  String _formatScheduleTime(CheckInHistoryItem checkIn) {
    String startTime = checkIn.scheduleStartTime ?? '';
    String endTime = checkIn.scheduleEndTime ?? '';
    
    // Remove segundos se houver (formato HH:mm:ss -> HH:mm)
    if (startTime.length > 5) {
      startTime = startTime.substring(0, 5);
    }
    if (endTime.length > 5) {
      endTime = endTime.substring(0, 5);
    }
    
    String dayInfo = '';
    if (checkIn.scheduleDayOfWeek != null) {
      // O banco usa 0=domingo, 1=segunda, etc.
      // _getDayName espera weekday do DateTime (1=segunda, 7=domingo)
      // Precisamos converter: 0->7, 1->1, 2->2, ..., 6->6
      int weekday = checkIn.scheduleDayOfWeek! == 0 
          ? 7 
          : checkIn.scheduleDayOfWeek!;
      dayInfo = '${_getDayName(weekday)} • ';
    }
    
    return '$dayInfo$startTime - $endTime';
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

