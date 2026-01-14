import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// Implementação Supabase do repositório de horários
class ClassScheduleRepositorySupabase implements ClassScheduleRepository {
  ClassScheduleRepositorySupabase() : _supabaseService = SupabaseService();

  final SupabaseService _supabaseService;

  @override
  Future<Result<List<ClassSchedule>>> getClassSchedules(
    String academyId, {
    String? modalityId,
    int? dayOfWeek,
    bool? isActive,
  }) async {
    try {
      final schedules = await _supabaseService.getClassSchedules(
        academyId,
        modalityId: modalityId,
        dayOfWeek: dayOfWeek,
        isActive: isActive,
      );

      final classSchedules = schedules
          .map((s) => ClassSchedule.fromMap(s))
          .toList();

      return Result.success(classSchedules);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar horários: $e'),
      );
    }
  }

  @override
  Future<Result<ClassSchedule?>> getClassSchedule(String id) async {
    try {
      final schedule = await _supabaseService.getClassSchedule(id);
      if (schedule == null) {
        return Result.success(null);
      }
      return Result.success(ClassSchedule.fromMap(schedule));
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar horário: $e'),
      );
    }
  }

  @override
  Future<Result<ClassSchedule>> createClassSchedule(
    ClassSchedule schedule,
  ) async {
    try {
      final data = schedule.toMap();
      // Remove id se estiver presente (será gerado pelo banco)
      data.remove('id');
      
      final created = await _supabaseService.createClassSchedule(data);
      return Result.success(ClassSchedule.fromMap(created));
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar horário: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateClassSchedule(
    String id,
    ClassSchedule schedule,
  ) async {
    try {
      final data = schedule.toMap();
      // Remove id e campos que não devem ser atualizados
      data.remove('id');
      data.remove('created_at');
      
      await _supabaseService.updateClassSchedule(id, data);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar horário: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteClassSchedule(String id) async {
    try {
      await _supabaseService.deleteClassSchedule(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao deletar horário: $e'),
      );
    }
  }

  @override
  Future<Result<List<ClassSchedule>>> getAvailableSchedulesForCheckIn(
    String academyId,
  ) async {
    try {
      final schedules = await _supabaseService.getAvailableSchedulesForCheckIn(
        academyId,
      );

      final classSchedules = schedules
          .map((s) => ClassSchedule.fromMap(s))
          .toList();

      return Result.success(classSchedules);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar horários disponíveis: $e'),
      );
    }
  }
}

