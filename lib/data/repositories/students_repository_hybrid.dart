import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Migração gradual: usa Backend API quando possível, com fallback para Supabase.
class StudentsRepositoryHybrid implements StudentsRepository {
  StudentsRepositoryHybrid({
    required BackendApiClient backendApiClient,
  })  : _backendApiClient = backendApiClient;

  final BackendApiClient _backendApiClient;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<List<AcademyStudent>>> getAcademyStudents(String academyId) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
    }

    try {
      final response = await _backendApiClient.get('/v1/academies/$academyId/students');

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(Failure(message: 'Erro ao buscar alunos', code: 'academy_students_not_found'));
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapAcademyStudentFromBackend)
          .toList();

      return Result.success(items);
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao buscar alunos', code: 'academy_students_not_found'));
    }
  }

  @override
  Future<Result<AcademyStudent?>> getStudent(String memberId) async {
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
  }

  @override
  Future<Result<void>> promoteStudent({
    required String studentModalityId,
    required String newBeltId,
    int degree = 0,
    String? promotedBy,
    String? notes,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
    }

    try {
      final response = await _backendApiClient.post(
        '/v1/student-modalities/$studentModalityId/promotions',
        body: {
          'new_belt_id': newBeltId,
          'degree': degree,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (!response.isSuccess) {
        return Result.failure(Failure(message: 'Erro ao promover aluno', code: 'student_promotion_failed'));
      }

      return Result.success(null);
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao promover aluno', code: 'student_promotion_failed'));
    }
  }

  @override
  Future<Result<void>> updateStudentClasses({
    required String studentModalityId,
    required int totalClasses,
    required int classesAtCurrentBelt,
  }) async {
    // Ainda não há endpoint específico para atualizar aulas por student_modality_id
    // sem academyId/memberId, então mantemos no fallback (Supabase) por enquanto.
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
  }

  @override
  Future<Result<void>> checkIn({
    required String studentModalityId,
    String? classScheduleId,
    String? classType,
    String? notes,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
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
        return Result.failure(Failure(message: 'Erro ao check-in', code: 'check_in_failed'));
      }

      return Result.success(null);
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao check-in', code: 'check_in_failed'));
    }
  }

  @override
  Future<Result<List<CheckInRecord>>> getCheckInHistory({
    required String studentModalityId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
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
        return Result.failure(Failure(message: 'Erro ao buscar histórico de check-ins', code: 'check_in_history_not_found'));
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapCheckInRecord)
          .toList();

      return Result.success(items);
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao buscar histórico de check-ins', code: 'check_in_history_not_found'));
    }
  }

  @override
  Future<Result<void>> enrollInModality({
    required String memberId,
    required String academyModalityId,
    required String martialArtType,
    required String initialBeltId,
    int initialDegree = 0,
  }) async {
    // A API de backend exige academyId e memberId na rota; como aqui só temos
    // memberId e academyModalityId, mantemos a matrícula via fallback Supabase.
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
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

  AcademyStudent _mapAcademyStudentFromBackend(Map<String, dynamic> data) {
    final member = data;
    final userData = (data['user'] as Map<String, dynamic>?) ?? {};
    final modalitiesData = (data['modalities'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    // Parse role
    final roleStr = member['role'] as String? ?? 'student';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.student,
    );

    // Parse status
    final statusStr = member['status'] as String? ?? 'pending';
    final status = AcademyStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AcademyStatus.pending,
    );

    // Parse payment status (opcional na API)
    final paymentStr = member['payment_status'] as String?;
    final paymentStatus = paymentStr != null
        ? PaymentStatus.values.firstWhere(
            (p) => p.name == paymentStr,
            orElse: () => PaymentStatus.pending,
          )
        : null;

    final modalities =
        modalitiesData.map(_mapStudentModalityFromBackend).toList();

    return AcademyStudent(
      memberId: member['id'] as String? ?? '',
      oderId: member['user_id'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      displayName: userData['display_name'] as String?,
      photoUrl: userData['photo_url'] as String?,
      role: role,
      status: status,
      joinedAt: member['joined_at'] != null
          ? DateTime.parse(member['joined_at'].toString())
          : DateTime.now(),
      paymentStatus: paymentStatus,
      paymentDueDate: member['payment_due_date'] != null
          ? DateTime.parse(member['payment_due_date'].toString())
          : null,
      modalities: modalities,
    );
  }

  StudentModalityInfo _mapStudentModalityFromBackend(
      Map<String, dynamic> data) {
    final typeStr = data['martial_art_type'] as String? ?? 'jiuJitsu';
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    final historyData = data['graduation_history'] as List<dynamic>? ?? [];
    final graduationHistory = historyData.map((h) {
      final hData = h as Map<String, dynamic>;
      return GraduationHistoryInfo(
        id: hData['id'] as String? ?? '',
        beltId: hData['belt_id'] as String? ?? '',
        degree: hData['degree'] as int? ?? 0,
        date: DateTime.parse(hData['promoted_at'].toString()),
        promotedBy: hData['promoted_by'] as String?,
        notes: hData['notes'] as String?,
      );
    }).toList();

    return StudentModalityInfo(
      id: data['id'] as String? ?? '',
      modalityId: data['modality_id'] as String? ?? '',
      type: type,
      beltId: data['belt_id'] as String? ?? '',
      degree: data['degree'] as int? ?? 0,
      totalClasses: data['total_classes'] as int? ?? 0,
      classesAtCurrentBelt: data['classes_at_current_belt'] as int? ?? 0,
      promotionDate: data['promotion_date'] != null
          ? DateTime.parse(data['promotion_date'].toString())
          : null,
      enrolledAt: data['enrolled_at'] != null
          ? DateTime.parse(data['enrolled_at'].toString())
          : DateTime.now(),
      assignedTeacherId: data['assigned_teacher_id'] as String?,
      graduationHistory: graduationHistory,
    );
  }
}

