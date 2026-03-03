import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/data/dtos/backend/me_response_dto.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// ViewModel para gerenciar histórico de check-ins
class CheckInHistoryViewModel extends ChangeNotifier {
  CheckInHistoryViewModel({
    required StudentsRepository studentsRepository,
    required BackendApiClient backendApiClient,
    required String userId,
  })  : _studentsRepository = studentsRepository,
        _backendApiClient = backendApiClient,
        _userId = userId;

  final StudentsRepository _studentsRepository;
  final BackendApiClient _backendApiClient;
  final String _userId;

  List<CheckInHistoryItem> _checkIns = [];
  List<StudentModalityInfo> _modalities = [];
  String? _selectedModalityId;
  bool _isLoading = false;
  String? _error;

  List<CheckInHistoryItem> get checkIns => _checkIns;
  List<StudentModalityInfo> get modalities => _modalities;
  String? get selectedModalityId => _selectedModalityId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega modalidades do aluno e histórico de check-ins
  Future<void> loadHistory({String? modalityId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
        '[CheckInHistoryViewModel] Carregando histórico de check-ins para usuário $_userId',
      );

      // 1) Busca dados do usuário logado (inclui student_modalities)
      final meResponse = await _backendApiClient.get('/v1/me');
      if (!meResponse.isSuccess || meResponse.data is! Map<String, dynamic>) {
        _error = 'Não foi possível carregar suas modalidades para histórico.';
        _checkIns = [];
        _modalities = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dto = BackendMeResponseDto.fromJson(
        (meResponse.data as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );

      // Mapeia modalidades do DTO para modelo local do histórico
      final modalities = dto.studentModalities.map((m) {
        MartialArtType type = MartialArtType.jiuJitsu;
        try {
          type = MartialArtType.values.firstWhere(
            (t) => t.name == m.martialArtType,
          );
        } catch (_) {
          type = MartialArtType.jiuJitsu;
        }

        return StudentModalityInfo(
          id: m.id,
          type: type,
          beltId: m.beltId,
          degree: m.degree,
          totalClasses: m.totalClasses,
          classesAtCurrentBelt: m.classesAtCurrentBelt,
          promotionDate: m.promotionDate,
          enrolledAt: m.enrolledAt ?? DateTime.now(),
        );
      }).toList();

      _modalities = modalities;

      if (_modalities.isEmpty) {
        _checkIns = [];
        _selectedModalityId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2) Decide qual modalidade usar para buscar o histórico
      final effectiveModalityId = modalityId ??
          _selectedModalityId ??
          dto.primaryStudentModalityId ??
          _modalities.first.id;

      _selectedModalityId = effectiveModalityId;

      final modalityById = {
        for (final m in _modalities) m.id: m,
      };

      // 3) Busca histórico de check-ins para a modalidade escolhida
      final historyResult = await _studentsRepository.getCheckInHistory(
        studentModalityId: effectiveModalityId,
      );

      historyResult.fold(
        onSuccess: (records) {
          _checkIns = records
              .map(
                (r) => CheckInHistoryItem(
                  id: r.id,
                  checkedInAt: r.checkedInAt,
                  classType: r.classType,
                  notes: r.notes,
                  modality:
                      modalityById[effectiveModalityId] ?? _modalities.first,
                  scheduleStartTime: r.scheduleStartTime,
                  scheduleEndTime: r.scheduleEndTime,
                  scheduleDayOfWeek: r.scheduleDayOfWeek,
                  modalityType: r.modalityType,
                ),
              )
              .toList();
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (failure) {
          _error = failure.message;
          _checkIns = [];
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Erro ao carregar histórico: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra por modalidade
  void filterByModality(String? modalityId) {
    loadHistory(modalityId: modalityId);
  }
}

/// Item do histórico de check-in
class CheckInHistoryItem {
  const CheckInHistoryItem({
    required this.id,
    required this.checkedInAt,
    this.classType,
    this.notes,
    required this.modality,
    this.scheduleStartTime,
    this.scheduleEndTime,
    this.scheduleDayOfWeek,
    this.modalityType,
  });

  final String id;
  final DateTime checkedInAt;
  final String? classType;
  final String? notes;
  final StudentModalityInfo modality;
  final String? scheduleStartTime; // Formato HH:mm
  final String? scheduleEndTime; // Formato HH:mm
  final int? scheduleDayOfWeek;
  final String? modalityType; // Nome da modalidade do horário
}

/// Informações da modalidade do aluno (simplificado)
class StudentModalityInfo {
  const StudentModalityInfo({
    required this.id,
    required this.type,
    required this.beltId,
    this.degree = 0,
    required this.totalClasses,
    required this.classesAtCurrentBelt,
    this.promotionDate,
    required this.enrolledAt,
  });

  final String id;
  final MartialArtType type;
  final String beltId;
  final int degree;
  final int totalClasses;
  final int classesAtCurrentBelt;
  final DateTime? promotionDate;
  final DateTime enrolledAt;

  MartialArt get martialArt => MartialArtsConfig.getByType(type);
}

