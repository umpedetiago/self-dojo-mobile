import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Modelo de horário de aula
class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.academyId,
    this.modalityId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classType = 'regular',
    this.instructorId,
    this.instructorName,
    this.instructorPhotoUrl,
    this.isActive = true,
    this.maxStudents,
    this.notes,
    this.modalityType,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String academyId;
  final String? modalityId;
  final int dayOfWeek; // 0 = domingo, 1 = segunda, ..., 6 = sábado
  final DateTime startTime; // Apenas hora/minuto
  final DateTime endTime; // Apenas hora/minuto
  final String classType; // 'regular', 'sparring', 'open_mat', 'kids', etc
  final String? instructorId;
  final String? instructorName;
  final String? instructorPhotoUrl;
  final bool isActive;
  final int? maxStudents;
  final String? notes;
  final MartialArtType? modalityType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nome do dia da semana
  String get dayName {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    return days[dayOfWeek];
  }

  /// Nome curto do dia da semana
  String get dayNameShort {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[dayOfWeek];
  }

  /// Formata o horário de início
  String get startTimeFormatted {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formata o horário de fim
  String get endTimeFormatted {
    final hour = endTime.hour.toString().padLeft(2, '0');
    final minute = endTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formata o intervalo de horário
  String get timeRange => '$startTimeFormatted - $endTimeFormatted';

  /// Cria a partir de um Map (do Supabase)
  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    // Parse do start_time e end_time (TIME do PostgreSQL)
    DateTime? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(2000, 1, 1, hour, minute);
      }
      return null;
    }

    final modality = map['academy_modalities'] as Map<String, dynamic>?;
    final instructor = map['users'] as Map<String, dynamic>?;

    return ClassSchedule(
      id: map['id'] as String,
      academyId: map['academy_id'] as String,
      modalityId: map['modality_id'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      startTime: parseTime(map['start_time'] as String?) ?? DateTime(2000, 1, 1, 0, 0),
      endTime: parseTime(map['end_time'] as String?) ?? DateTime(2000, 1, 1, 0, 0),
      classType: map['class_type'] as String? ?? 'regular',
      instructorId: map['instructor_id'] as String?,
      instructorName: instructor?['display_name'] as String?,
      instructorPhotoUrl: instructor?['photo_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      maxStudents: map['max_students'] as int?,
      notes: map['notes'] as String?,
      modalityType: modality?['martial_art_type'] != null
          ? (() {
              try {
                return MartialArtType.values.firstWhere(
                  (t) => t.name == modality!['martial_art_type'] as String,
                );
              } catch (_) {
                return null;
              }
            })()
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Converte para Map (para Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academy_id': academyId,
      if (modalityId != null) 'modality_id': modalityId,
      'day_of_week': dayOfWeek,
      'start_time': startTimeFormatted,
      'end_time': endTimeFormatted,
      'class_type': classType,
      if (instructorId != null) 'instructor_id': instructorId,
      'is_active': isActive,
      if (maxStudents != null) 'max_students': maxStudents,
      if (notes != null) 'notes': notes,
    };
  }

  /// Cria uma cópia com campos atualizados
  ClassSchedule copyWith({
    String? id,
    String? academyId,
    String? modalityId,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    String? classType,
    String? instructorId,
    String? instructorName,
    String? instructorPhotoUrl,
    bool? isActive,
    int? maxStudents,
    String? notes,
    MartialArtType? modalityType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      modalityId: modalityId ?? this.modalityId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classType: classType ?? this.classType,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      instructorPhotoUrl: instructorPhotoUrl ?? this.instructorPhotoUrl,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
      notes: notes ?? this.notes,
      modalityType: modalityType ?? this.modalityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClassSchedule(id: $id, day: $dayName, time: $timeRange, type: $classType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

