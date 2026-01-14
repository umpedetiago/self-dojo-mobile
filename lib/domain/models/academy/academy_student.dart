import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Representa um aluno da academia com suas informações e modalidades
class AcademyStudent extends Equatable {
  const AcademyStudent({
    required this.memberId,
    required this.oderId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.student,
    required this.status,
    required this.joinedAt,
    this.paymentStatus,
    this.paymentDueDate,
    this.modalities = const [],
  });

  /// ID do membership (academy_members)
  final String memberId;

  /// ID do usuário
  final String oderId;

  /// Email do aluno
  final String email;

  /// Nome do aluno
  final String? displayName;

  /// Foto do aluno
  final String? photoUrl;

  /// Role do aluno
  final UserRole role;

  /// Status na academia
  final AcademyStatus status;

  /// Data de entrada na academia
  final DateTime joinedAt;

  /// Status de pagamento
  final PaymentStatus? paymentStatus;

  /// Data de vencimento do pagamento
  final DateTime? paymentDueDate;

  /// Modalidades matriculadas
  final List<StudentModalityInfo> modalities;

  /// Nome para exibição
  String get name => displayName ?? email.split('@').first;

  /// Verifica se está aprovado
  bool get isApproved => status == AcademyStatus.approved;

  /// Verifica se pagamento está em dia
  bool get isPaymentActive =>
      paymentStatus == null ||
      paymentStatus == PaymentStatus.active ||
      paymentStatus == PaymentStatus.exempt;

  /// Retorna a modalidade principal (primeira)
  StudentModalityInfo? get primaryModality =>
      modalities.isNotEmpty ? modalities.first : null;

  /// Retorna total de aulas em todas modalidades
  int get totalClasses => modalities.fold(0, (sum, m) => sum + m.totalClasses);

  /// Busca modalidade por tipo
  StudentModalityInfo? getModality(MartialArtType type) {
    try {
      return modalities.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        memberId,
        oderId,
        email,
        displayName,
        photoUrl,
        role,
        status,
        joinedAt,
        paymentStatus,
        paymentDueDate,
        modalities,
      ];
}

/// Informações da modalidade do aluno
class StudentModalityInfo extends Equatable {
  const StudentModalityInfo({
    required this.id,
    required this.type,
    required this.beltId,
    this.degree = 0,
    required this.totalClasses,
    required this.classesAtCurrentBelt,
    this.promotionDate,
    required this.enrolledAt,
    this.assignedTeacherId,
    this.graduationHistory = const [],
  });

  /// ID do student_modality
  final String id;

  /// Tipo da arte marcial
  final MartialArtType type;

  /// ID da faixa atual
  final String beltId;

  /// Grau atual
  final int degree;

  /// Total de aulas
  final int totalClasses;

  /// Aulas na faixa atual
  final int classesAtCurrentBelt;

  /// Data da última promoção
  final DateTime? promotionDate;

  /// Data de matrícula na modalidade
  final DateTime enrolledAt;

  /// ID do professor responsável
  final String? assignedTeacherId;

  /// Histórico de graduações
  final List<GraduationHistoryInfo> graduationHistory;

  /// Retorna a arte marcial
  MartialArt get martialArt => MartialArtsConfig.getByType(type);

  /// Retorna a faixa atual
  Belt? get currentBelt => martialArt.getBeltById(beltId);

  /// Retorna a próxima faixa
  Belt? get nextBelt {
    final current = currentBelt;
    if (current == null) return null;
    return martialArt.getNextBelt(current);
  }

  /// Calcula aulas restantes para promoção
  int get classesUntilPromotion {
    final next = nextBelt;
    if (next == null) return 0;
    final remaining = next.minClassesForPromotion - classesAtCurrentBelt;
    return remaining > 0 ? remaining : 0;
  }

  /// Tempo de treino na modalidade
  Duration get trainingTime => DateTime.now().difference(enrolledAt);

  /// Copia com alterações
  StudentModalityInfo copyWith({
    String? id,
    MartialArtType? type,
    String? beltId,
    int? degree,
    int? totalClasses,
    int? classesAtCurrentBelt,
    DateTime? promotionDate,
    DateTime? enrolledAt,
    String? assignedTeacherId,
    List<GraduationHistoryInfo>? graduationHistory,
  }) {
    return StudentModalityInfo(
      id: id ?? this.id,
      type: type ?? this.type,
      beltId: beltId ?? this.beltId,
      degree: degree ?? this.degree,
      totalClasses: totalClasses ?? this.totalClasses,
      classesAtCurrentBelt: classesAtCurrentBelt ?? this.classesAtCurrentBelt,
      promotionDate: promotionDate ?? this.promotionDate,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      assignedTeacherId: assignedTeacherId ?? this.assignedTeacherId,
      graduationHistory: graduationHistory ?? this.graduationHistory,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        beltId,
        degree,
        totalClasses,
        classesAtCurrentBelt,
        promotionDate,
        enrolledAt,
        assignedTeacherId,
        graduationHistory,
      ];
}

/// Histórico de graduação
class GraduationHistoryInfo extends Equatable {
  const GraduationHistoryInfo({
    required this.id,
    required this.beltId,
    this.degree = 0,
    required this.date,
    this.promotedBy,
    this.notes,
  });

  final String id;
  final String beltId;
  final int degree;
  final DateTime date;
  final String? promotedBy;
  final String? notes;

  @override
  List<Object?> get props => [id, beltId, degree, date, promotedBy, notes];
}

