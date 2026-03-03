import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// ViewModel para gerenciar histórico de check-ins
class CheckInHistoryViewModel extends ChangeNotifier {
  CheckInHistoryViewModel({
    required StudentsRepository studentsRepository,
    required String userId,
  })  : _studentsRepository = studentsRepository,
        _userId = userId;

  final StudentsRepository _studentsRepository;
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
      // Usa dependências injetadas apenas para evitar warnings enquanto
      // a migração completa para Backend API não é concluída.
      final _ = _studentsRepository;
      debugPrint('Carregando histórico de check-ins para usuário $_userId');

      // TODO: Migrar para Backend API quando houver endpoint para
      // recuperar modalidades e histórico do aluno sem Supabase.
      _error =
          'Histórico de check-ins ainda não está disponível nesta versão (migração para Backend API em andamento).';
      _checkIns = [];
      _modalities = [];
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

