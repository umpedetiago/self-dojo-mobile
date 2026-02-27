import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository_supabase.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// Migração gradual: usa Backend API quando configurado, com fallback para Supabase.
class ClassScheduleRepositoryHybrid implements ClassScheduleRepository {
  ClassScheduleRepositoryHybrid({
    required BackendApiClient backendApiClient,
    ClassScheduleRepository? fallbackRepository,
  })  : _backendApiClient = backendApiClient,
        _fallbackRepository = fallbackRepository ?? ClassScheduleRepositorySupabase();

  final BackendApiClient _backendApiClient;
  final ClassScheduleRepository _fallbackRepository;
  final Map<String, String> _scheduleAcademyIdMap = {};

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<List<ClassSchedule>>> getClassSchedules(
    String academyId, {
    String? modalityId,
    int? dayOfWeek,
    bool? isActive,
  }) async {
    if (!_canUseBackend) {
      return _fallbackRepository.getClassSchedules(
        academyId,
        modalityId: modalityId,
        dayOfWeek: dayOfWeek,
        isActive: isActive,
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/class-schedules',
        queryParameters: {
          if (modalityId != null && modalityId.isNotEmpty) 'modalityId': modalityId,
          if (dayOfWeek != null) 'dayOfWeek': '$dayOfWeek',
          if (isActive != null) 'isActive': '$isActive',
        },
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return _fallbackRepository.getClassSchedules(
          academyId,
          modalityId: modalityId,
          dayOfWeek: dayOfWeek,
          isActive: isActive,
        );
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ClassSchedule.fromMap)
          .toList();

      for (final schedule in items) {
        _scheduleAcademyIdMap[schedule.id] = academyId;
      }

      return Result.success(items);
    } catch (_) {
      return _fallbackRepository.getClassSchedules(
        academyId,
        modalityId: modalityId,
        dayOfWeek: dayOfWeek,
        isActive: isActive,
      );
    }
  }

  @override
  Future<Result<ClassSchedule?>> getClassSchedule(String id) {
    // Interface atual não recebe academyId, então mantemos no Supabase.
    return _fallbackRepository.getClassSchedule(id);
  }

  @override
  Future<Result<ClassSchedule>> createClassSchedule(ClassSchedule schedule) async {
    if (!_canUseBackend) {
      return _fallbackRepository.createClassSchedule(schedule);
    }

    try {
      final payload = {
        if (schedule.modalityId != null) 'modality_id': schedule.modalityId,
        if (schedule.instructorId != null) 'instructor_id': schedule.instructorId,
        'day_of_week': schedule.dayOfWeek,
        'start_time': '${schedule.startTimeFormatted}:00',
        'end_time': '${schedule.endTimeFormatted}:00',
        'class_type': schedule.classType,
        'is_active': schedule.isActive,
        if (schedule.maxStudents != null) 'max_students': schedule.maxStudents,
        if (schedule.notes != null && schedule.notes!.isNotEmpty) 'notes': schedule.notes,
      };

      final response = await _backendApiClient.post(
        '/v1/academies/${schedule.academyId}/class-schedules',
        body: payload,
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return _fallbackRepository.createClassSchedule(schedule);
      }

      final created = ClassSchedule.fromMap(response.data as Map<String, dynamic>);
      _scheduleAcademyIdMap[created.id] = schedule.academyId;
      return Result.success(created);
    } catch (_) {
      return _fallbackRepository.createClassSchedule(schedule);
    }
  }

  @override
  Future<Result<void>> updateClassSchedule(String id, ClassSchedule schedule) async {
    if (!_canUseBackend) {
      return _fallbackRepository.updateClassSchedule(id, schedule);
    }

    try {
      final payload = {
        if (schedule.modalityId != null) 'modality_id': schedule.modalityId,
        if (schedule.instructorId != null) 'instructor_id': schedule.instructorId,
        'day_of_week': schedule.dayOfWeek,
        'start_time': '${schedule.startTimeFormatted}:00',
        'end_time': '${schedule.endTimeFormatted}:00',
        'class_type': schedule.classType,
        'is_active': schedule.isActive,
        'max_students': schedule.maxStudents,
        'notes': schedule.notes,
      };

      final response = await _backendApiClient.patch(
        '/v1/academies/${schedule.academyId}/class-schedules/$id',
        body: payload,
      );

      if (!response.isSuccess) {
        return _fallbackRepository.updateClassSchedule(id, schedule);
      }

      _scheduleAcademyIdMap[id] = schedule.academyId;
      return Result.success(null);
    } catch (_) {
      return _fallbackRepository.updateClassSchedule(id, schedule);
    }
  }

  @override
  Future<Result<void>> deleteClassSchedule(String id) async {
    final academyId = _scheduleAcademyIdMap[id];
    if (!_canUseBackend || academyId == null) {
      return _fallbackRepository.deleteClassSchedule(id);
    }

    try {
      final response = await _backendApiClient.delete(
        '/v1/academies/$academyId/class-schedules/$id',
      );
      if (!response.isSuccess) {
        return _fallbackRepository.deleteClassSchedule(id);
      }
      _scheduleAcademyIdMap.remove(id);
      return Result.success(null);
    } catch (_) {
      return _fallbackRepository.deleteClassSchedule(id);
    }
  }

  @override
  Future<Result<List<ClassSchedule>>> getAvailableSchedulesForCheckIn(
    String academyId,
  ) async {
    if (!_canUseBackend) {
      return _fallbackRepository.getAvailableSchedulesForCheckIn(academyId);
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/class-schedules/available-for-checkin',
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return _fallbackRepository.getAvailableSchedulesForCheckIn(academyId);
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ClassSchedule.fromMap)
          .toList();

      for (final schedule in items) {
        _scheduleAcademyIdMap[schedule.id] = academyId;
      }

      return Result.success(items);
    } catch (_) {
      return _fallbackRepository.getAvailableSchedulesForCheckIn(academyId);
    }
  }
}

