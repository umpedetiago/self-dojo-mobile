import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';

/// Repository para gerenciamento de alunos
abstract class StudentsRepository {
  /// Busca alunos da academia
  Future<Result<List<AcademyStudent>>> getAcademyStudents(String academyId);

  /// Busca aluno específico
  Future<Result<AcademyStudent?>> getStudent(String memberId);

  /// Promove aluno para nova graduação
  Future<Result<void>> promoteStudent({
    required String studentModalityId,
    required String newBeltId,
    int degree = 0,
    String? promotedBy,
    String? notes,
  });

  /// Atualiza contador de aulas do aluno
  Future<Result<void>> updateStudentClasses({
    required String studentModalityId,
    required int totalClasses,
    required int classesAtCurrentBelt,
  });

  /// Registra check-in do aluno
  Future<Result<void>> checkIn({
    required String studentModalityId,
    required String academyId,
    String? classType,
    String? notes,
  });

  /// Busca histórico de check-ins
  Future<Result<List<CheckInRecord>>> getCheckInHistory({
    required String studentModalityId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Matricula aluno em uma modalidade
  Future<Result<void>> enrollInModality({
    required String memberId,
    required String academyModalityId,
    required String martialArtType,
    required String initialBeltId,
    int initialDegree = 0,
  });

  /// Remove matrícula de modalidade
  Future<Result<void>> unenrollFromModality(String studentModalityId);
}

/// Registro de check-in
class CheckInRecord {
  const CheckInRecord({
    required this.id,
    required this.checkedInAt,
    this.classType,
    this.notes,
  });

  final String id;
  final DateTime checkedInAt;
  final String? classType;
  final String? notes;
}

