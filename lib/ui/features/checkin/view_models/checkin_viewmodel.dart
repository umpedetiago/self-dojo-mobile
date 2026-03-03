import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// ViewModel para gerenciar check-in do aluno
class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({
    required ClassScheduleRepository classScheduleRepository,
    required StudentsRepository studentsRepository,
    required ProfileService profileService,
    required String userId,
  })  : _classScheduleRepository = classScheduleRepository,
        _studentsRepository = studentsRepository,
        _profileService = profileService,
        _userId = userId;

  final ClassScheduleRepository _classScheduleRepository;
  final StudentsRepository _studentsRepository;
  final ProfileService _profileService;
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
      debugPrint('[CheckInViewModel] Carregando dados de check-in para usuário $_userId');

      final profile = _profileService.profile;
      if (!profile.hasAcademy || !profile.isApprovedInAcademy) {
        _error = 'Você precisa estar aprovado em uma academia para fazer check-in.';
        _availableSchedules = [];
        _studentModalityMap = {};
        _academyId = null;
        _memberId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final academyId = profile.academyId!;
      _academyId = academyId;

      // Busca os dados de membership e modalidades do aluno na academia.
      final studentsResult = await _studentsRepository.getAcademyStudents(academyId);

      AcademyStudent? me;
      studentsResult.fold(
        onSuccess: (students) {
          for (final s in students) {
            if (s.oderId == _userId) {
              me = s;
              break;
            }
          }
        },
        onFailure: (failure) {
          _error = failure.message;
        },
      );

      if (me == null) {
        _error ??= 'Seu cadastro na academia ainda não foi encontrado ou aprovado.';
        _availableSchedules = [];
        _studentModalityMap = {};
        _memberId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _memberId = me!.memberId;

      // Monta o mapa modalityId -> studentModalityId para validação de matrícula.
      _studentModalityMap = {
        for (final m in me!.modalities)
          if (m.modalityId.isNotEmpty) m.modalityId: m.id,
      };

      // Carrega horários disponíveis para check-in hoje.
      final schedulesResult =
          await _classScheduleRepository.getAvailableSchedulesForCheckIn(academyId);

      schedulesResult.fold(
        onSuccess: (schedules) {
          _availableSchedules = schedules;
        },
        onFailure: (failure) {
          _error = failure.message;
          _availableSchedules = [];
        },
      );

      _isLoading = false;
      notifyListeners();
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
    if (_studentModalityMap.isEmpty) {
      return false;
    }

    final studentModalityId = _studentModalityMap.values.first;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await _studentsRepository.getCheckInHistory(
      studentModalityId: studentModalityId,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return result.fold(
      onSuccess: (items) => items.isNotEmpty,
      onFailure: (_) => false,
    );
  }
}

