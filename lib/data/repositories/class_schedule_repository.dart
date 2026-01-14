import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository_supabase.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// Repository abstrato para gerenciamento de horários de aulas
abstract class ClassScheduleRepository {
  /// Busca horários da academia
  Future<Result<List<ClassSchedule>>> getClassSchedules(
    String academyId, {
    String? modalityId,
    int? dayOfWeek,
    bool? isActive,
  });

  /// Busca horário por ID
  Future<Result<ClassSchedule?>> getClassSchedule(String id);

  /// Cria horário de aula
  Future<Result<ClassSchedule>> createClassSchedule(ClassSchedule schedule);

  /// Atualiza horário de aula
  Future<Result<void>> updateClassSchedule(
    String id,
    ClassSchedule schedule,
  );

  /// Deleta horário de aula
  Future<Result<void>> deleteClassSchedule(String id);

  /// Busca horários disponíveis para check-in (horários ativos do dia atual)
  Future<Result<List<ClassSchedule>>> getAvailableSchedulesForCheckIn(
    String academyId,
  );
}

/// Factory para criar o repository correto
ClassScheduleRepository createClassScheduleRepository() {
  return ClassScheduleRepositorySupabase();
}

