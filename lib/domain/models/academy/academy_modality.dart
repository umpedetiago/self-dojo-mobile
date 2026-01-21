import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Configuração de graduação personalizada da academia
class GraduationConfig extends Equatable {
  const GraduationConfig({
    required this.martialArtType,
    this.belts = const [],
    this.useDefaultConfig = true,
    this.configuredBy,
    this.lastUpdated,
  });

  final MartialArtType martialArtType;
  final List<BeltConfig> belts;
  final bool useDefaultConfig;
  final String? configuredBy;
  final DateTime? lastUpdated;

  /// Retorna configuração de uma faixa específica
  BeltConfig? getBeltConfig(String beltId) {
    try {
      return belts.firstWhere((b) => b.beltId == beltId);
    } catch (_) {
      return null;
    }
  }

  /// Retorna aulas mínimas para uma faixa (usa padrão se não configurado)
  int getMinClasses(String beltId) {
    if (useDefaultConfig) {
      final martialArt = MartialArtsConfig.getByType(martialArtType);
      final belt = martialArt.getBeltById(beltId);
      return belt?.minClassesForPromotion ?? 0;
    }
    return getBeltConfig(beltId)?.minClasses ?? 0;
  }

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'martialArtType': martialArtType.name,
      'belts': belts.map((b) => b.toMap()).toList(),
      'useDefaultConfig': useDefaultConfig,
      'configuredBy': configuredBy,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Cria a partir de Map (Firestore)
  factory GraduationConfig.fromMap(Map<String, dynamic> map) {
    return GraduationConfig(
      martialArtType: MartialArtType.values.firstWhere(
        (t) => t.name == map['martialArtType'],
        orElse: () => MartialArtType.jiuJitsu,
      ),
      belts: (map['belts'] as List<dynamic>?)
              ?.map((b) => BeltConfig.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      useDefaultConfig: map['useDefaultConfig'] as bool? ?? true,
      configuredBy: map['configuredBy'] as String?,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : null,
    );
  }

  /// Copia com alterações
  GraduationConfig copyWith({
    MartialArtType? martialArtType,
    List<BeltConfig>? belts,
    bool? useDefaultConfig,
    String? configuredBy,
    DateTime? lastUpdated,
  }) {
    return GraduationConfig(
      martialArtType: martialArtType ?? this.martialArtType,
      belts: belts ?? this.belts,
      useDefaultConfig: useDefaultConfig ?? this.useDefaultConfig,
      configuredBy: configuredBy ?? this.configuredBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        martialArtType,
        belts,
        useDefaultConfig,
        configuredBy,
        lastUpdated,
      ];
}

/// Configuração personalizada de uma faixa
class BeltConfig extends Equatable {
  const BeltConfig({
    required this.beltId,
    required this.minClasses,
    this.minMonths,
    this.minClassesPerDegree,
    this.requiresExam = false,
    this.examFee,
    this.notes,
  });

  final String beltId;
  final int minClasses;
  final int? minMonths;
  final int? minClassesPerDegree;
  final bool requiresExam;
  final double? examFee;
  final String? notes;

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'beltId': beltId,
      'minClasses': minClasses,
      'minMonths': minMonths,
      'minClassesPerDegree': minClassesPerDegree,
      'requiresExam': requiresExam,
      'examFee': examFee,
      'notes': notes,
    };
  }

  /// Cria a partir de Map (Firestore)
  factory BeltConfig.fromMap(Map<String, dynamic> map) {
    return BeltConfig(
      beltId: map['beltId'] as String,
      minClasses: map['minClasses'] as int? ?? 0,
      minMonths: map['minMonths'] as int?,
      minClassesPerDegree: map['minClassesPerDegree'] as int?,
      requiresExam: map['requiresExam'] as bool? ?? false,
      examFee: (map['examFee'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        beltId,
        minClasses,
        minMonths,
        minClassesPerDegree,
        requiresExam,
        examFee,
        notes,
      ];
}

/// Modalidade oferecida pela academia
class AcademyModality extends Equatable {
  const AcademyModality({
    required this.id,
    required this.type,
    this.masterId,
    this.masterName,
    this.teacherIds = const [],
    this.instructorIds = const [],
    required this.graduationConfig,
    this.isActive = true,
  });

  /// ID da modalidade na academia
  final String id;

  /// Tipo da arte marcial
  final MartialArtType type;

  /// ID do Mestre desta modalidade (pode ser null = Owner gerencia)
  final String? masterId;

  /// Nome do Mestre (quando disponível)
  final String? masterName;

  /// IDs dos professores desta modalidade
  final List<String> teacherIds;

  /// IDs dos instrutores desta modalidade
  final List<String> instructorIds;

  /// Configuração de graduação desta modalidade
  final GraduationConfig graduationConfig;

  /// Se a modalidade está ativa
  final bool isActive;

  /// Retorna a arte marcial
  MartialArt get martialArt => MartialArtsConfig.getByType(type);

  /// Retorna uma faixa com requisitos do banco quando disponível
  /// Combina informações visuais (cor, nome) locais com requisitos (minClasses, minMonths) do banco
  Belt? getBeltWithDatabaseConfig(String beltId) {
    final baseBelt = martialArt.getBeltById(beltId);
    if (baseBelt == null) return null;

    // Se usa configuração padrão, retorna a faixa local
    if (graduationConfig.useDefaultConfig) return baseBelt;

    // Busca configuração do banco
    final beltConfig = graduationConfig.getBeltConfig(beltId);
    if (beltConfig == null) return baseBelt;

    // Retorna faixa combinando informações visuais locais com requisitos do banco
    return Belt(
      id: baseBelt.id,
      name: baseBelt.name,
      color: baseBelt.color,
      secondaryColor: baseBelt.secondaryColor,
      order: baseBelt.order,
      maxDegrees: baseBelt.maxDegrees,
      minClassesForPromotion: beltConfig.minClasses, // Do banco
      minMonthsAtBelt: beltConfig.minMonths, // Do banco
      hasBlackTip: baseBelt.hasBlackTip,
      degreeMarkColor: baseBelt.degreeMarkColor,
      tipColor: baseBelt.tipColor,
    );
  }

  /// Retorna todas as faixas com requisitos do banco quando disponível
  List<Belt> get beltsWithDatabaseConfig {
    if (graduationConfig.useDefaultConfig) return martialArt.belts;

    return martialArt.belts.map((baseBelt) {
      final beltConfig = graduationConfig.getBeltConfig(baseBelt.id);
      if (beltConfig == null) return baseBelt;

      return Belt(
        id: baseBelt.id,
        name: baseBelt.name,
        color: baseBelt.color,
        secondaryColor: baseBelt.secondaryColor,
        order: baseBelt.order,
        maxDegrees: baseBelt.maxDegrees,
        minClassesForPromotion: beltConfig.minClasses,
        minMonthsAtBelt: beltConfig.minMonths,
        hasBlackTip: baseBelt.hasBlackTip,
        degreeMarkColor: baseBelt.degreeMarkColor,
        tipColor: baseBelt.tipColor,
      );
    }).toList();
  }

  /// Verifica se o usuário é mestre desta modalidade
  bool isMaster(String userId) => masterId == userId;

  /// Verifica se o usuário é professor desta modalidade
  bool isTeacher(String userId) => teacherIds.contains(userId);

  /// Verifica se o usuário é instrutor desta modalidade
  bool isInstructor(String userId) => instructorIds.contains(userId);

  /// Verifica se o usuário faz parte da equipe
  bool isStaff(String userId) =>
      isMaster(userId) || isTeacher(userId) || isInstructor(userId);

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'masterId': masterId,
      'teacherIds': teacherIds,
      'instructorIds': instructorIds,
      'graduationConfig': graduationConfig.toMap(),
      'isActive': isActive,
    };
  }

  /// Cria a partir de Map (Firestore)
  factory AcademyModality.fromMap(Map<String, dynamic> map) {
    return AcademyModality(
      id: map['id'] as String? ?? '',
      type: MartialArtType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MartialArtType.jiuJitsu,
      ),
      masterId: map['masterId'] as String?,
      teacherIds: (map['teacherIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      instructorIds: (map['instructorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      graduationConfig:
          GraduationConfig.fromMap(map['graduationConfig'] as Map<String, dynamic>),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Copia com alterações
  AcademyModality copyWith({
    String? id,
    MartialArtType? type,
    String? masterId,
    String? masterName,
    List<String>? teacherIds,
    List<String>? instructorIds,
    GraduationConfig? graduationConfig,
    bool? isActive,
  }) {
    return AcademyModality(
      id: id ?? this.id,
      type: type ?? this.type,
      masterId: masterId ?? this.masterId,
      masterName: masterName ?? this.masterName,
      teacherIds: teacherIds ?? this.teacherIds,
      instructorIds: instructorIds ?? this.instructorIds,
      graduationConfig: graduationConfig ?? this.graduationConfig,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        masterId,
        masterName,
        teacherIds,
        instructorIds,
        graduationConfig,
        isActive,
      ];
}

