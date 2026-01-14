import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/class_schedule.dart';

/// ViewModel para gerenciar horários de aulas
class ClassScheduleViewModel extends ChangeNotifier {
  ClassScheduleViewModel({
    required ClassScheduleRepository classScheduleRepository,
    required String academyId,
  })  : _repository = classScheduleRepository,
        _academyId = academyId;

  final ClassScheduleRepository _repository;
  final String _academyId;

  List<ClassSchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<ClassSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega horários da academia
  Future<void> loadSchedules({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getClassSchedules(
      _academyId,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (schedules) {
        _schedules = schedules;
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Cria novo horário
  Future<Result<ClassSchedule>> createSchedule(ClassSchedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.createClassSchedule(schedule);

    result.fold(
      onSuccess: (created) {
        _schedules.add(created);
        _schedules.sort((a, b) {
          if (a.dayOfWeek != b.dayOfWeek) {
            return a.dayOfWeek.compareTo(b.dayOfWeek);
          }
          return a.startTime.compareTo(b.startTime);
        });
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );

    return result;
  }

  /// Atualiza horário
  Future<Result<void>> updateSchedule(ClassSchedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.updateClassSchedule(schedule.id, schedule);

    result.fold(
      onSuccess: (_) {
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule;
          _schedules.sort((a, b) {
            if (a.dayOfWeek != b.dayOfWeek) {
              return a.dayOfWeek.compareTo(b.dayOfWeek);
            }
            return a.startTime.compareTo(b.startTime);
          });
        }
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );

    return result;
  }

  /// Deleta horário
  Future<Result<void>> deleteSchedule(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.deleteClassSchedule(id);

    result.fold(
      onSuccess: (_) {
        _schedules.removeWhere((s) => s.id == id);
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );

    return result;
  }

  /// Busca horários por dia da semana
  List<ClassSchedule> getSchedulesByDay(int dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Busca horários por modalidade
  List<ClassSchedule> getSchedulesByModality(String modalityId) {
    return _schedules
        .where((s) => s.modalityId == modalityId)
        .toList()
      ..sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startTime.compareTo(b.startTime);
      });
  }

  /// Agrupa horários por dia da semana
  Map<int, List<ClassSchedule>> get schedulesByDay {
    final map = <int, List<ClassSchedule>>{};
    for (final schedule in _schedules) {
      map.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
    }
    // Ordena horários dentro de cada dia
    for (final day in map.keys) {
      map[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }
}

