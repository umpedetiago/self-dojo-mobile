import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// ViewModel para gerenciar check-in do aluno
class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({
    required ClassScheduleRepository classScheduleRepository,
    required StudentsRepository studentsRepository,
    required SupabaseService supabaseService,
    required String userId,
  })  : _classScheduleRepository = classScheduleRepository,
        _studentsRepository = studentsRepository,
        _supabaseService = supabaseService,
        _userId = userId;

  final ClassScheduleRepository _classScheduleRepository;
  final StudentsRepository _studentsRepository;
  final SupabaseService _supabaseService;
  final String _userId;

  List<ClassSchedule> _availableSchedules = [];
  String? _academyId;
  String? _memberId;
  Map<String, String> _studentModalityMap = {}; // modalityId -> studentModalityId
  bool _isLoading = false;
  String? _error;

  List<ClassSchedule> get availableSchedules => _availableSchedules;
  String? get academyId => _academyId;
  String? get memberId => _memberId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega informações do aluno e horários disponíveis
  Future<void> loadCheckInData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Primeiro busca o usuário pelo Firebase UID para obter o UUID do banco
      final user = await _supabaseService.getUserByFirebaseUid(_userId);
      if (user == null) {
        _error = 'Usuário não encontrado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dbUserId = user['id'] as String;

      // Busca o membro do aluno usando o UUID do banco
      final member = await _supabaseService.getMemberByUserId(dbUserId);
      if (member == null) {
        _error = 'Você não está matriculado em nenhuma academia';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _memberId = member['id'] as String;
      _academyId = member['academy_id'] as String;

      // Busca modalidades do aluno e cria mapa
      final modalities = await _supabaseService.getStudentModalities(_memberId!);
      _studentModalityMap = {};
      for (final modality in modalities) {
        final modalityId = modality['modality_id'] as String?;
        final studentModalityId = modality['id'] as String;
        if (modalityId != null) {
          _studentModalityMap[modalityId] = studentModalityId;
        }
      }

      // Busca horários disponíveis para check-in
      final schedulesResult = await _classScheduleRepository
          .getAvailableSchedulesForCheckIn(_academyId!);

      schedulesResult.fold(
        onSuccess: (schedules) {
          // Filtra apenas horários das modalidades que o aluno está matriculado
          // ou horários sem modalidade específica (para todas)
          _availableSchedules = schedules.where((schedule) {
            if (schedule.modalityId == null) {
              // Horário para todas as modalidades
              return true;
            }
            // Verifica se o aluno está matriculado nesta modalidade
            return _studentModalityMap.containsKey(schedule.modalityId);
          }).toList();
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (failure) {
          _error = failure.message;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Erro ao carregar horários: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Faz check-in em um horário
  Future<Result<void>> checkIn(ClassSchedule schedule) async {
    if (_academyId == null || _memberId == null) {
      return Result.failure(
        Failure(message: 'Dados do aluno não carregados'),
      );
    }

    // Busca o student_modality_id correspondente
    String? studentModalityId;
    if (schedule.modalityId != null) {
      studentModalityId = _studentModalityMap[schedule.modalityId];
      if (studentModalityId == null) {
        return Result.failure(
          Failure(message: 'Você não está matriculado nesta modalidade'),
        );
      }
    } else {
      // Se o horário é para todas as modalidades, usa a primeira modalidade do aluno
      if (_studentModalityMap.isEmpty) {
        return Result.failure(
          Failure(message: 'Você não está matriculado em nenhuma modalidade'),
        );
      }
      studentModalityId = _studentModalityMap.values.first;
    }

    _isLoading = true;
    notifyListeners();

    final result = await _studentsRepository.checkIn(
      studentModalityId: studentModalityId,
      classScheduleId: schedule.id,
      classType: schedule.classType,
    );

    result.fold(
      onSuccess: (_) {
        _isLoading = false;
        // Recarrega os horários após check-in
        loadCheckInData();
      },
      onFailure: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );

    return result;
  }

  /// Verifica se o aluno já fez check-in hoje em algum horário
  Future<bool> hasCheckedInToday() async {
    if (_memberId == null) return false;

    try {
      final modalities = await _supabaseService.getStudentModalities(_memberId!);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (final modality in modalities) {
        final studentModalityId = modality['id'] as String;
        final checkIns = await _supabaseService.getStudentCheckIns(
          studentModalityId,
          startDate: todayStart,
        );

        if (checkIns.isNotEmpty) {
          // Verifica se há check-in de hoje
          for (final checkIn in checkIns) {
            final checkedInAt = DateTime.parse(checkIn['checked_in_at'] as String);
            if (checkedInAt.isAfter(todayStart) || checkedInAt.isAtSameMomentAs(todayStart)) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

