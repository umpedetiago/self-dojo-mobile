import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// Implementação baseada na Backend API.
class ClassScheduleRepositoryHybrid implements ClassScheduleRepository {
  ClassScheduleRepositoryHybrid({
    required BackendApiClient backendApiClient,
  }) : _backendApiClient = backendApiClient;

  final BackendApiClient _backendApiClient;
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
      return Result.failure(
        const Failure(message: 'Backend API não configurada para horários'),
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
        return Result.failure(
          Failure(
            message:
                'Erro ao buscar horários (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
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
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar horários: $e'),
      );
    }
  }

  @override
  Future<Result<ClassSchedule?>> getClassSchedule(String id) async {
    // A API atual exige academyId na rota; mantemos não implementado.
    return Result.failure(
      const Failure(message: 'getClassSchedule ainda não suportado via API'),
    );
  }

  @override
  Future<Result<ClassSchedule>> createClassSchedule(ClassSchedule schedule) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para horários'),
      );
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
        return Result.failure(
          Failure(
            message:
                'Erro ao criar horário (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final created = ClassSchedule.fromMap(response.data as Map<String, dynamic>);
      _scheduleAcademyIdMap[created.id] = schedule.academyId;
      return Result.success(created);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar horário: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateClassSchedule(String id, ClassSchedule schedule) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para horários'),
      );
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
        return Result.failure(
          Failure(
            message:
                'Erro ao atualizar horário (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      _scheduleAcademyIdMap[id] = schedule.academyId;
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar horário: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteClassSchedule(String id) async {
    final academyId = _scheduleAcademyIdMap[id];
    if (!_canUseBackend || academyId == null) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para horários'),
      );
    }

    try {
      final response = await _backendApiClient.delete(
        '/v1/academies/$academyId/class-schedules/$id',
      );
      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao excluir horário (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }
      _scheduleAcademyIdMap.remove(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao excluir horário: $e'),
      );
    }
  }

  @override
  Future<Result<List<ClassSchedule>>> getAvailableSchedulesForCheckIn(
    String academyId,
  ) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para horários'),
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/class-schedules/available-for-checkin',
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao buscar horários para check-in (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
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
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar horários para check-in: $e'),
      );
    }
  }
}

