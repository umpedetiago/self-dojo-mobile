import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
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
  bool _isLoading = false;
  String? _error;

  List<ClassSchedule> get availableSchedules => _availableSchedules;
  String? get academyId => _academyId;
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
        _academyId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final academyId = profile.academyId!;
      _academyId = academyId;

      // Carrega horários disponíveis para check-in hoje a partir da Backend API.
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
    if (_academyId == null) {
      return Result.failure(
        Failure(message: 'Dados do aluno não carregados'),
      );
    }

    _isLoading = true;
    notifyListeners();

    final result = await _studentsRepository.checkIn(
      studentModalityId: '', // resolvido no backend (/v1/me/check-ins)
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
    // Ainda não há endpoint específico para \"meus check-ins do dia\"; por
    // enquanto não bloqueamos check-in repetido no cliente.
    return false;
  }
}

