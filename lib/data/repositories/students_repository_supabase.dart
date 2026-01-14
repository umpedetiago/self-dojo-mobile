import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_student.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Implementação do StudentsRepository usando Supabase
class StudentsRepositorySupabase implements StudentsRepository {
  StudentsRepositorySupabase({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<List<AcademyStudent>>> getAcademyStudents(
      String academyId) async {
    try {
      // Busca membros aprovados da academia
      final members = await _supabaseService.getAcademyMembers(
        academyId,
        status: 'approved',
      );

      final students = <AcademyStudent>[];

      for (final member in members) {
        final userData = member['users'] as Map<String, dynamic>?;
        if (userData == null) continue;

        // Busca modalidades do aluno
        final modalities =
            await _supabaseService.getStudentModalities(member['id']);

        students.add(_mapToStudent(member, userData, modalities));
      }

      // Ordena por nome
      students.sort((a, b) => a.name.compareTo(b.name));

      return Result.success(students);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar alunos: $e'));
    }
  }

  @override
  Future<Result<AcademyStudent?>> getStudent(String memberId) async {
    try {
      // Busca o membro específico
      // Note: Precisamos implementar um método para buscar por ID
      // Por enquanto, retornamos null
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar aluno: $e'));
    }
  }

  @override
  Future<Result<void>> promoteStudent({
    required String studentModalityId,
    required String newBeltId,
    int degree = 0,
    String? promotedBy,
    String? notes,
  }) async {
    try {
      await _supabaseService.promoteStudent(
        studentModalityId: studentModalityId,
        newBeltId: newBeltId,
        degree: degree,
        promotedBy: promotedBy,
        notes: notes,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao promover aluno: $e'));
    }
  }

  @override
  Future<Result<void>> updateStudentClasses({
    required String studentModalityId,
    required int totalClasses,
    required int classesAtCurrentBelt,
  }) async {
    try {
      await _supabaseService.updateStudentModality(studentModalityId, {
        'total_classes': totalClasses,
        'classes_at_current_belt': classesAtCurrentBelt,
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao atualizar aulas: $e'));
    }
  }

  @override
  Future<Result<void>> checkIn({
    required String studentModalityId,
    String? classScheduleId,
    String? classType,
    String? notes,
  }) async {
    try {
      await _supabaseService.createCheckIn({
        'student_modality_id': studentModalityId,
        if (classScheduleId != null) 'class_schedule_id': classScheduleId,
        'class_type': classType,
        'notes': notes,
        'checked_in_at': DateTime.now().toIso8601String(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao registrar check-in: $e'));
    }
  }

  @override
  Future<Result<List<CheckInRecord>>> getCheckInHistory({
    required String studentModalityId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final checkIns = await _supabaseService.getStudentCheckIns(
        studentModalityId,
        startDate: startDate,
        endDate: endDate,
      );

      final records = checkIns.map((c) {
        final schedule = c['class_schedules'] as Map<String, dynamic>?;
        final modality = schedule?['academy_modalities'] as Map<String, dynamic>?;
        
        return CheckInRecord(
          id: c['id'] as String,
          checkedInAt: DateTime.parse(c['checked_in_at'] as String),
          classType: c['class_type'] as String?,
          notes: c['notes'] as String?,
          classScheduleId: schedule?['id'] as String?,
          scheduleStartTime: schedule?['start_time'] as String?,
          scheduleEndTime: schedule?['end_time'] as String?,
          scheduleDayOfWeek: schedule?['day_of_week'] as int?,
          modalityType: modality?['martial_art_type'] as String?,
        );
      }).toList();

      return Result.success(records);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao buscar histórico de check-ins: $e'));
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
    try {
      // Usa modality_id que referencia academy_modalities
      await _supabaseService.enrollInModality({
        'member_id': memberId,
        'modality_id': academyModalityId,
        'belt_id': initialBeltId,
        'degree': initialDegree,
        'total_classes': 0,
        'classes_at_current_belt': 0,
        'enrolled_at': DateTime.now().toIso8601String(),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao matricular em modalidade: $e'));
    }
  }

  @override
  Future<Result<void>> unenrollFromModality(String studentModalityId) async {
    try {
      await _supabaseService.deleteStudentModality(studentModalityId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao remover matrícula: $e'));
    }
  }

  // ============================================
  // MAPPERS
  // ============================================

  AcademyStudent _mapToStudent(
    Map<String, dynamic> member,
    Map<String, dynamic> userData,
    List<Map<String, dynamic>> modalitiesData,
  ) {
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

    // Parse payment status
    final paymentStr = member['payment_status'] as String?;
    final paymentStatus = paymentStr != null
        ? PaymentStatus.values.firstWhere(
            (p) => p.name == paymentStr,
            orElse: () => PaymentStatus.pending,
          )
        : null;

    // Parse modalidades
    final modalities = modalitiesData.map(_mapToModalityInfo).toList();

    return AcademyStudent(
      memberId: member['id'] as String,
      oderId: member['user_id'] as String,
      email: userData['email'] as String? ?? '',
      displayName: userData['display_name'] as String?,
      photoUrl: userData['photo_url'] as String?,
      role: role,
      status: status,
      joinedAt: member['joined_at'] != null
          ? DateTime.parse(member['joined_at'] as String)
          : DateTime.now(),
      paymentStatus: paymentStatus,
      paymentDueDate: member['payment_due_date'] != null
          ? DateTime.parse(member['payment_due_date'] as String)
          : null,
      modalities: modalities,
    );
  }

  StudentModalityInfo _mapToModalityInfo(Map<String, dynamic> data) {
    // Parse tipo - vem do campo martial_art_type (buscado de academy_modalities)
    final typeStr = data['martial_art_type'] as String? ?? 'jiuJitsu';
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    // Parse histórico
    final historyData = data['graduation_history'] as List<dynamic>? ?? [];
    final graduationHistory = historyData.map((h) {
      final hData = h as Map<String, dynamic>;
      return GraduationHistoryInfo(
        id: hData['id'] as String,
        beltId: hData['belt_id'] as String,
        degree: hData['degree'] as int? ?? 0,
        date: DateTime.parse(hData['promoted_at'] as String),
        promotedBy: hData['promoted_by'] as String?,
        notes: hData['notes'] as String?,
      );
    }).toList();

    return StudentModalityInfo(
      id: data['id'] as String,
      type: type,
      beltId: data['belt_id'] as String? ?? 'white',
      degree: data['degree'] as int? ?? 0,
      totalClasses: data['total_classes'] as int? ?? 0,
      classesAtCurrentBelt: data['classes_at_current_belt'] as int? ?? 0,
      promotionDate: data['promotion_date'] != null
          ? DateTime.parse(data['promotion_date'] as String)
          : null,
      enrolledAt: data['enrolled_at'] != null
          ? DateTime.parse(data['enrolled_at'] as String)
          : DateTime.now(),
      assignedTeacherId: data['assigned_teacher_id'] as String?,
      graduationHistory: graduationHistory,
    );
  }
}

