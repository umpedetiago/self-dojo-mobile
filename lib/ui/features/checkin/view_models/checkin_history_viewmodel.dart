import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// ViewModel para gerenciar histórico de check-ins
class CheckInHistoryViewModel extends ChangeNotifier {
  CheckInHistoryViewModel({
    required StudentsRepository studentsRepository,
    required SupabaseService supabaseService,
    required String userId,
  })  : _studentsRepository = studentsRepository,
        _supabaseService = supabaseService,
        _userId = userId;

  final StudentsRepository _studentsRepository;
  final SupabaseService _supabaseService;
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
    _selectedModalityId = modalityId;
    notifyListeners();

    try {
      // Busca o usuário pelo Firebase UID
      final user = await _supabaseService.getUserByFirebaseUid(_userId);
      if (user == null) {
        _error = 'Usuário não encontrado';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dbUserId = user['id'] as String;

      // Busca o membro do aluno
      final member = await _supabaseService.getMemberByUserId(dbUserId);
      if (member == null) {
        _error = 'Você não está matriculado em nenhuma academia';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final memberId = member['id'] as String;

      // Busca modalidades do aluno
      final modalitiesData = await _supabaseService.getStudentModalities(memberId);
      _modalities = modalitiesData.map((m) {
        final martialArtTypeStr = m['martial_art_type'] as String?;
        MartialArtType? martialArtType;
        if (martialArtTypeStr != null) {
          try {
            martialArtType = MartialArtType.values.firstWhere(
              (t) => t.name == martialArtTypeStr,
            );
          } catch (_) {
            martialArtType = null;
          }
        }

        return StudentModalityInfo(
          id: m['id'] as String,
          type: martialArtType ?? MartialArtType.jiuJitsu,
          beltId: m['belt_id'] as String,
          degree: m['degree'] as int? ?? 0,
          totalClasses: m['total_classes'] as int? ?? 0,
          classesAtCurrentBelt: m['classes_at_current_belt'] as int? ?? 0,
          promotionDate: m['promotion_date'] != null
              ? DateTime.parse(m['promotion_date'] as String)
              : null,
          enrolledAt: m['enrolled_at'] != null
              ? DateTime.parse(m['enrolled_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      // Se não há modalidades, retorna
      if (_modalities.isEmpty) {
        _checkIns = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Se uma modalidade específica foi selecionada, busca apenas dela
      // Senão, busca de todas as modalidades
      final List<CheckInHistoryItem> allCheckIns = [];

      final modalitiesToLoad = modalityId != null
          ? _modalities.where((m) => m.id == modalityId).toList()
          : _modalities;

      for (final modality in modalitiesToLoad) {
        final result = await _studentsRepository.getCheckInHistory(
          studentModalityId: modality.id,
        );

        result.fold(
          onSuccess: (records) {
            for (final record in records) {
              allCheckIns.add(CheckInHistoryItem(
                id: record.id,
                checkedInAt: record.checkedInAt,
                classType: record.classType,
                notes: record.notes,
                modality: modality,
                scheduleStartTime: record.scheduleStartTime,
                scheduleEndTime: record.scheduleEndTime,
                scheduleDayOfWeek: record.scheduleDayOfWeek,
                modalityType: record.modalityType,
              ));
            }
          },
          onFailure: (_) {},
        );
      }

      // Ordena por data (mais recente primeiro)
      allCheckIns.sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));

      _checkIns = allCheckIns;
      _isLoading = false;
      notifyListeners();
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

