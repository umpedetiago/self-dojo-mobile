import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Matrícula do aluno em uma modalidade específica
/// Cada modalidade tem sua própria graduação, histórico e contador de aulas
class StudentModality extends Equatable {
  const StudentModality({
    required this.type,
    this.assignedTeacherId,
    required this.graduation,
    this.graduationHistory = const [],
    this.totalClasses = 0,
    required this.enrolledAt,
    this.academyModality,
  });

  /// Tipo da arte marcial
  final MartialArtType type;

  /// ID do professor responsável nesta modalidade
  final String? assignedTeacherId;

  /// Graduação atual nesta modalidade
  final UserGraduation graduation;

  /// Histórico de graduações nesta modalidade
  final List<GraduationHistory> graduationHistory;

  /// Total de aulas nesta modalidade
  final int totalClasses;

  /// Data de matrícula nesta modalidade
  final DateTime enrolledAt;

  /// Modalidade da academia (opcional, usado para obter requisitos do banco)
  final AcademyModality? academyModality;

  /// Retorna a arte marcial
  MartialArt get martialArt => MartialArtsConfig.getByType(type);

  /// Retorna a faixa atual (usa requisitos do banco se academyModality disponível)
  Belt? get currentBelt {
    if (academyModality != null) {
      return academyModality!.getBeltWithDatabaseConfig(graduation.beltId);
    }
    return martialArt.getBeltById(graduation.beltId);
  }

  /// Retorna a próxima faixa (usa requisitos do banco se academyModality disponível)
  Belt? get nextBelt {
    final current = currentBelt;
    if (current == null) return null;
    
    if (academyModality != null) {
      final belts = academyModality!.beltsWithDatabaseConfig;
      if (belts == null) return null;
      final currentIndex = belts.indexWhere((b) => b.id == current.id);
      if (currentIndex == -1 || currentIndex >= belts.length - 1) {
        return null;
      }
      return belts[currentIndex + 1];
    }
    
    return martialArt.getNextBelt(current);
  }

  /// Aulas restantes até a próxima faixa, considerando a configuração da academia
  int get classesUntilNextBelt {
    final next = nextBelt;
    if (next == null) return 0;

    final targetClasses = next.minClassesForPromotion;
    if (targetClasses <= 0) return 0;

    final remaining = targetClasses - graduation.classesAtCurrentBelt;
    return remaining > 0 ? remaining : 0;
  }

  /// Aulas restantes até o próximo grau na faixa atual, usando `minClassesPerDegree` da academia
  int get classesUntilNextDegree {
    final current = currentBelt;
    if (current == null) return 0;

    // Se não há graus configurados para a faixa, não há próximo grau
    if (current.maxDegrees <= 0) return 0;
    if (graduation.degree >= current.maxDegrees) return 0;

    // Busca configuração específica da faixa na academia (quando existir)
    final beltConfig = academyModality?.graduationConfig
        .getBeltConfig(graduation.beltId);

    final perDegree = beltConfig?.minClassesPerDegree;
    if (perDegree == null || perDegree <= 0) return 0;

    // Threshold cumulativo esperado para o próximo grau
    final targetTotalForNextDegree =
        perDegree * (graduation.degree + 1);

    final remaining =
        targetTotalForNextDegree - graduation.classesAtCurrentBelt;
    return remaining > 0 ? remaining : 0;
  }

  /// Tempo de treino nesta modalidade
  Duration get trainingTime => DateTime.now().difference(enrolledAt);

  /// Cria matrícula inicial em uma modalidade
  factory StudentModality.initial(MartialArtType type) {
    final martialArt = MartialArtsConfig.getByType(type);
    return StudentModality(
      type: type,
      graduation: UserGraduation.initial(martialArt.initialBelt?.id ?? ''),
      enrolledAt: DateTime.now(),
    );
  }

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'assignedTeacherId': assignedTeacherId,
      'graduation': graduation.toMap(),
      'graduationHistory': graduationHistory.map((g) => g.toMap()).toList(),
      'totalClasses': totalClasses,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }

  /// Cria a partir de Map (Firestore)
  factory StudentModality.fromMap(Map<String, dynamic> map) {
    return StudentModality(
      type: MartialArtType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MartialArtType.jiuJitsu,
      ),
      assignedTeacherId: map['assignedTeacherId'] as String?,
      graduation:
          UserGraduation.fromMap(map['graduation'] as Map<String, dynamic>),
      graduationHistory: (map['graduationHistory'] as List<dynamic>?)
              ?.map((g) => GraduationHistory.fromMap(g as Map<String, dynamic>))
              .toList() ??
          [],
      totalClasses: map['totalClasses'] as int? ?? 0,
      enrolledAt: DateTime.parse(map['enrolledAt'] as String),
    );
  }

  /// Copia com alterações
  StudentModality copyWith({
    MartialArtType? type,
    String? assignedTeacherId,
    UserGraduation? graduation,
    List<GraduationHistory>? graduationHistory,
    int? totalClasses,
    DateTime? enrolledAt,
    AcademyModality? academyModality,
  }) {
    return StudentModality(
      type: type ?? this.type,
      assignedTeacherId: assignedTeacherId ?? this.assignedTeacherId,
      graduation: graduation ?? this.graduation,
      graduationHistory: graduationHistory ?? this.graduationHistory,
      totalClasses: totalClasses ?? this.totalClasses,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      academyModality: academyModality ?? this.academyModality,
    );
  }

  /// Incrementa contador de aulas
  StudentModality incrementClasses() {
    return copyWith(
      totalClasses: totalClasses + 1,
      graduation: graduation.copyWith(
        classesAtCurrentBelt: graduation.classesAtCurrentBelt + 1,
      ),
    );
  }

  /// Promove para nova graduação
  StudentModality promote({
    required String newBeltId,
    int degree = 0,
    String? notes,
  }) {
    final now = DateTime.now();

    // Nova graduação
    final newGraduation = UserGraduation(
      beltId: newBeltId,
      degree: degree,
      promotionDate: now,
      classesAtCurrentBelt: 0,
    );

    // Adiciona ao histórico
    final newHistory = GraduationHistory(
      beltId: newBeltId,
      degree: degree,
      date: now,
      notes: notes,
    );

    return copyWith(
      graduation: newGraduation,
      graduationHistory: [...graduationHistory, newHistory],
    );
  }

  @override
  List<Object?> get props => [
        type,
        assignedTeacherId,
        graduation,
        graduationHistory,
        totalClasses,
        enrolledAt,
        academyModality,
      ];
}

