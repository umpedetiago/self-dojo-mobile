import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// ViewModel para gerenciamento de alunos da academia
class StudentsViewModel extends ChangeNotifier {
  StudentsViewModel({
    required StudentsRepository studentsRepository,
    required String academyId,
  })  : _studentsRepository = studentsRepository,
        _academyId = academyId {
    promoteStudent = Command1(_promoteStudent);
    updateStudentClasses = Command1(_updateStudentClasses);
    _loadStudents();
  }

  final StudentsRepository _studentsRepository;
  final String _academyId;

  // State
  List<AcademyStudent> _students = [];
  List<AcademyStudent> get students => _students;

  List<AcademyStudent> _filteredStudents = [];
  List<AcademyStudent> get filteredStudents => _filteredStudents;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  MartialArtType? _filterModality;
  MartialArtType? get filterModality => _filterModality;

  // Commands
  late final Command1<void, PromoteStudentParams> promoteStudent;
  late final Command1<void, UpdateClassesParams> updateStudentClasses;

  /// Carrega alunos da academia
  Future<void> _loadStudents() async {
    _isLoading = true;
    notifyListeners();

    final result = await _studentsRepository.getAcademyStudents(_academyId);

    result.fold(
      onSuccess: (students) {
        _students = students;
        _applyFilters();
        _isLoading = false;
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  /// Recarrega a lista de alunos
  Future<void> refresh() async {
    await _loadStudents();
  }

  /// Busca por nome/email
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filtra por modalidade
  void filterByModality(MartialArtType? type) {
    _filterModality = type;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica os filtros
  void _applyFilters() {
    var result = _students;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) {
        final name = s.displayName?.toLowerCase() ?? '';
        final email = s.email.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Filtro por modalidade
    if (_filterModality != null) {
      result = result.where((s) {
        return s.modalities.any((m) => m.type == _filterModality);
      }).toList();
    }

    _filteredStudents = result;
  }

  /// Promove aluno para nova graduação
  Future<Result<void>> _promoteStudent(PromoteStudentParams params) async {
    final result = await _studentsRepository.promoteStudent(
      studentModalityId: params.studentModalityId,
      newBeltId: params.newBeltId,
      degree: params.degree,
      promotedBy: params.promotedBy,
      notes: params.notes,
    );

    if (result.isSuccess) {
      await _loadStudents();
    }

    return result;
  }

  /// Atualiza contador de aulas do aluno
  Future<Result<void>> _updateStudentClasses(UpdateClassesParams params) async {
    final result = await _studentsRepository.updateStudentClasses(
      studentModalityId: params.studentModalityId,
      totalClasses: params.totalClasses,
      classesAtCurrentBelt: params.classesAtCurrentBelt,
    );

    if (result.isSuccess) {
      await _loadStudents();
    }

    return result;
  }

  /// Busca aluno por ID
  AcademyStudent? getStudent(String memberId) {
    try {
      return _students.firstWhere((s) => s.memberId == memberId);
    } catch (_) {
      return null;
    }
  }

  /// Matricula aluno em modalidade
  Future<Result<void>> enrollInModality(EnrollModalityParams params) async {
    final result = await _studentsRepository.enrollInModality(
      memberId: params.memberId,
      academyModalityId: params.academyModalityId,
      martialArtType: params.martialArtType,
      initialBeltId: params.initialBeltId,
      initialDegree: params.initialDegree,
    );

    if (result.isSuccess) {
      await _loadStudents();
    }

    return result;
  }

  /// Remove matrícula de modalidade
  // Future<Result<void>> unenrollFromModality(String studentModalityId) async {
  //   final result = await _studentsRepository.unenrollFromModality(studentModalityId);

  //   if (result.isSuccess) {
  //     await _loadStudents();
  //   }

  //   return result;
  // }
}

/// Parâmetros para matrícula em modalidade
class EnrollModalityParams {
  const EnrollModalityParams({
    required this.memberId,
    required this.academyModalityId,
    required this.martialArtType,
    required this.initialBeltId,
    this.initialDegree = 0,
  });

  final String memberId;
  final String academyModalityId;
  final String martialArtType;
  final String initialBeltId;
  final int initialDegree;
}

/// Parâmetros para promoção
class PromoteStudentParams {
  const PromoteStudentParams({
    required this.studentModalityId,
    required this.newBeltId,
    this.degree = 0,
    this.promotedBy,
    this.notes,
  });

  final String studentModalityId;
  final String newBeltId;
  final int degree;
  final String? promotedBy;
  final String? notes;
}

/// Parâmetros para atualizar aulas
class UpdateClassesParams {
  const UpdateClassesParams({
    required this.studentModalityId,
    required this.totalClasses,
    required this.classesAtCurrentBelt,
  });

  final String studentModalityId;
  final int totalClasses;
  final int classesAtCurrentBelt;
}

