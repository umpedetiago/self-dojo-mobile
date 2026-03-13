class BackendMeResponseDto {
  BackendMeResponseDto({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    this.martialArtType,
    this.hasAparadores,
    this.primaryStudentModalityId,
    this.studentModalities = const [],
    this.academyId,
    this.academyStatus,
    this.joinedAt,
    this.academyName,
    this.instructorName,
    this.weightCategory,
    this.totalClassesAll,
    this.classesUntilNextBelt,
    this.classesUntilNextDegree,
    this.trainingTimeDays,
    this.competitionsCount,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role;
  final String? martialArtType;
  final bool? hasAparadores;

  final String? primaryStudentModalityId;
  final List<BackendStudentModalityDto> studentModalities;

  final String? academyId;
  final String? academyStatus;
  final DateTime? joinedAt;

  /// Dados agregados e de exibição vindos do backend
  final String? academyName;
  final String? instructorName;
  final String? weightCategory;

  final int? totalClassesAll;
  final int? classesUntilNextBelt;
  final int? classesUntilNextDegree;
  final int? trainingTimeDays;
  final int? competitionsCount;

  final DateTime? createdAt;

  factory BackendMeResponseDto.fromJson(Map<String, dynamic> json) {
    final modalitiesRaw = json['student_modalities'];
    final modalities = (modalitiesRaw is List)
        ? modalitiesRaw
            .whereType<Map>()
            .map((m) => BackendStudentModalityDto.fromJson(
                  m.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList()
        : <BackendStudentModalityDto>[];

    return BackendMeResponseDto(
      id: (json['id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      role: (json['role'] as String?) ?? 'student',
      martialArtType: json['martial_art_type'] as String?,
      hasAparadores: json['has_aparadores'] as bool?,
      primaryStudentModalityId: json['primary_student_modality_id'] as String?,
      studentModalities: modalities,
      academyId: json['academy_id'] as String?,
      academyStatus: json['academy_status'] as String?,
      joinedAt: DateTime.tryParse((json['joined_at'] as String?) ?? ''),
      academyName: json['academy_name'] as String?,
      instructorName: json['instructor_name'] as String?,
      weightCategory: json['weight_category'] as String?,
      totalClassesAll: json['total_classes_all'] as int?,
      classesUntilNextBelt: json['classes_until_next_belt'] as int?,
      classesUntilNextDegree: json['classes_until_next_degree'] as int?,
      trainingTimeDays: json['training_time_days'] as int?,
      competitionsCount: json['competitions_count'] as int?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
    );
  }
}

class BackendStudentModalityDto {
  BackendStudentModalityDto({
    required this.id,
    required this.memberId,
    required this.modalityId,
    required this.martialArtType,
    this.assignedTeacherId,
    required this.beltId,
    this.degree = 0,
    this.promotionDate,
    this.totalClasses = 0,
    this.classesAtCurrentBelt = 0,
    this.enrolledAt,
    this.graduationHistory = const [],
    this.classesUntilNextBelt,
    this.classesUntilNextDegree,
    this.trainingTimeDays,
  });

  final String id;
  final String memberId;
  final String modalityId;
  final String martialArtType;
  final String? assignedTeacherId;
  final String beltId;
  final int degree;
  final DateTime? promotionDate;
  final int totalClasses;
  final int classesAtCurrentBelt;
  final DateTime? enrolledAt;
  final List<BackendGraduationHistoryItemDto> graduationHistory;

  /// Valores já calculados pelo backend (opcionais)
  final int? classesUntilNextBelt;
  final int? classesUntilNextDegree;
  final int? trainingTimeDays;

  factory BackendStudentModalityDto.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['graduation_history'];
    final history = (historyRaw is List)
        ? historyRaw
            .whereType<Map>()
            .map((h) => BackendGraduationHistoryItemDto.fromJson(
                  h.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList()
        : <BackendGraduationHistoryItemDto>[];

    return BackendStudentModalityDto(
      id: (json['id'] as String?) ?? '',
      memberId: (json['member_id'] as String?) ?? '',
      modalityId: (json['modality_id'] as String?) ?? '',
      martialArtType: (json['martial_art_type'] as String?) ?? '',
      assignedTeacherId: json['assigned_teacher_id'] as String?,
      beltId: (json['belt_id'] as String?) ?? '',
      degree: (json['degree'] as int?) ?? 0,
      promotionDate: DateTime.tryParse((json['promotion_date'] as String?) ?? ''),
      totalClasses: (json['total_classes'] as int?) ?? 0,
      classesAtCurrentBelt: (json['classes_at_current_belt'] as int?) ?? 0,
      enrolledAt: DateTime.tryParse((json['enrolled_at'] as String?) ?? ''),
      graduationHistory: history,
      classesUntilNextBelt: json['classes_until_next_belt'] as int?,
      classesUntilNextDegree: json['classes_until_next_degree'] as int?,
      trainingTimeDays: json['training_time_days'] as int?,
    );
  }
}

class BackendGraduationHistoryItemDto {
  BackendGraduationHistoryItemDto({
    required this.id,
    required this.studentModalityId,
    required this.beltId,
    this.degree = 0,
    this.promotedAt,
    this.promotedBy,
    this.notes,
  });

  final String id;
  final String studentModalityId;
  final String beltId;
  final int degree;
  final DateTime? promotedAt;
  final String? promotedBy;
  final String? notes;

  factory BackendGraduationHistoryItemDto.fromJson(Map<String, dynamic> json) {
    return BackendGraduationHistoryItemDto(
      id: (json['id'] as String?) ?? '',
      studentModalityId: (json['student_modality_id'] as String?) ?? '',
      beltId: (json['belt_id'] as String?) ?? '',
      degree: (json['degree'] as int?) ?? 0,
      promotedAt: DateTime.tryParse((json['promoted_at'] as String?) ?? ''),
      promotedBy: json['promoted_by'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

