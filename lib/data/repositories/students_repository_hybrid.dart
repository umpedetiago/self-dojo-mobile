import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';

/// Migracao gradual: usa Backend API quando possivel, com fallback para Supabase.
class StudentsRepositoryHybrid implements StudentsRepository {
  StudentsRepositoryHybrid({
    required BackendApiClient backendApiClient,
    required StudentsRepository fallbackRepository,
  })  : _backendApiClient = backendApiClient,
        _fallbackRepository = fallbackRepository;

  final BackendApiClient _backendApiClient;
  final StudentsRepository _fallbackRepository;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<List<AcademyStudent>>> getAcademyStudents(String academyId) {
    return _fallbackRepository.getAcademyStudents(academyId);
  }

  @override
  Future<Result<AcademyStudent?>> getStudent(String memberId) {
    return _fallbackRepository.getStudent(memberId);
  }

  @override
  Future<Result<void>> promoteStudent({
    required String studentModalityId,
    required String newBeltId,
    int degree = 0,
    String? promotedBy,
    String? notes,
  }) {
    return _fallbackRepository.promoteStudent(
      studentModalityId: studentModalityId,
      newBeltId: newBeltId,
      degree: degree,
      promotedBy: promotedBy,
      notes: notes,
    );
  }

  @override
  Future<Result<void>> updateStudentClasses({
    required String studentModalityId,
    required int totalClasses,
    required int classesAtCurrentBelt,
  }) {
    return _fallbackRepository.updateStudentClasses(
      studentModalityId: studentModalityId,
      totalClasses: totalClasses,
      classesAtCurrentBelt: classesAtCurrentBelt,
    );
  }

  @override
  Future<Result<void>> checkIn({
    required String studentModalityId,
    String? classScheduleId,
    String? classType,
    String? notes,
  }) async {
    if (!_canUseBackend) {
      return _fallbackRepository.checkIn(
        studentModalityId: studentModalityId,
        classScheduleId: classScheduleId,
        classType: classType,
        notes: notes,
      );
    }

    try {
      final response = await _backendApiClient.post(
        '/v1/check-ins',
        body: {
          'student_modality_id': studentModalityId,
          if (classScheduleId != null && classScheduleId.isNotEmpty)
            'class_schedule_id': classScheduleId,
          if (classType != null && classType.isNotEmpty) 'class_type': classType,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (!response.isSuccess) {
        return _fallbackRepository.checkIn(
          studentModalityId: studentModalityId,
          classScheduleId: classScheduleId,
          classType: classType,
          notes: notes,
        );
      }

      return Result.success(null);
    } catch (_) {
      return _fallbackRepository.checkIn(
        studentModalityId: studentModalityId,
        classScheduleId: classScheduleId,
        classType: classType,
        notes: notes,
      );
    }
  }

  @override
  Future<Result<List<CheckInRecord>>> getCheckInHistory({
    required String studentModalityId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_canUseBackend) {
      return _fallbackRepository.getCheckInHistory(
        studentModalityId: studentModalityId,
        startDate: startDate,
        endDate: endDate,
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/student-modalities/$studentModalityId/check-ins',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return _fallbackRepository.getCheckInHistory(
          studentModalityId: studentModalityId,
          startDate: startDate,
          endDate: endDate,
        );
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapCheckInRecord)
          .toList();

      return Result.success(items);
    } catch (_) {
      return _fallbackRepository.getCheckInHistory(
        studentModalityId: studentModalityId,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  @override
  Future<Result<void>> enrollInModality({
    required String memberId,
    required String academyModalityId,
    required String martialArtType,
    required String initialBeltId,
    int initialDegree = 0,
  }) {
    return _fallbackRepository.enrollInModality(
      memberId: memberId,
      academyModalityId: academyModalityId,
      martialArtType: martialArtType,
      initialBeltId: initialBeltId,
      initialDegree: initialDegree,
    );
  }

  @override
  Future<Result<void>> unenrollFromModality(String studentModalityId) {
    return _fallbackRepository.unenrollFromModality(studentModalityId);
  }

  CheckInRecord _mapCheckInRecord(Map<String, dynamic> map) {
    return CheckInRecord(
      id: map['id'] as String? ?? '',
      checkedInAt: DateTime.tryParse(map['checked_in_at'] as String? ?? '') ??
          DateTime.now(),
      classType: map['class_type'] as String?,
      notes: map['notes'] as String?,
      classScheduleId: map['class_schedule_id'] as String?,
      // Endpoint atual nao inclui detalhes do horario/modality no response.
      scheduleStartTime: null,
      scheduleEndTime: null,
      scheduleDayOfWeek: null,
      modalityType: null,
    );
  }
}

