import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/academy/student_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Perfil completo do usuário
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.student,
    // Campos de academia
    this.academyId,
    this.academyStatus,
    this.managedModalities,
    this.enrolledModalities = const [],
    this.planId,
    this.joinedAcademyAt,
    this.paymentStatus,
    this.paymentDueDate,
    // Campos legados (para usuários sem academia)
    this.martialArtType,  // Selecionado no cadastro
    this.graduation,
    this.graduationHistory = const [],
    this.academyName,
    this.instructorName,
    this.startDate,
    this.weightCategory,
    this.competitions = const [],
    this.totalClasses = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// ID do usuário (Firebase Auth UID)
  final String id;

  /// Email do usuário
  final String email;

  /// Nome de exibição
  final String? displayName;

  /// URL da foto de perfil
  final String? photoUrl;

  /// Role do usuário no sistema
  final UserRole role;

  // ============================================
  // CAMPOS DE ACADEMIA
  // ============================================

  /// ID da academia vinculada
  final String? academyId;

  /// Status na academia
  final AcademyStatus? academyStatus;

  /// Modalidades que gerencia (para mestres de modalidade)
  final List<MartialArtType>? managedModalities;

  /// Modalidades matriculadas (para alunos)
  final List<StudentModality> enrolledModalities;

  /// ID do plano contratado
  final String? planId;

  /// Data de entrada na academia
  final DateTime? joinedAcademyAt;

  /// Status de pagamento
  final PaymentStatus? paymentStatus;

  /// Data de vencimento do pagamento
  final DateTime? paymentDueDate;

  // ============================================
  // CAMPOS LEGADOS (usuários sem academia)
  // ============================================

  /// Tipo de arte marcial praticada (selecionado no cadastro)
  final MartialArtType? martialArtType;

  /// Graduação atual (legado - para usuários sem academia)
  final UserGraduation? graduation;

  /// Histórico de graduações (legado)
  final List<GraduationHistory> graduationHistory;

  /// Nome da Academia/Dojô (legado - texto livre)
  final String? academyName;

  /// Nome do Professor/Mestre (legado - texto livre)
  final String? instructorName;

  /// Data de início nos treinos
  final DateTime? startDate;

  /// Categoria de peso
  final String? weightCategory;

  /// Lista de competições
  final List<Competition> competitions;

  /// Total de aulas realizadas (legado)
  final int totalClasses;

  /// Data de criação do perfil
  final DateTime? createdAt;

  /// Data da última atualização
  final DateTime? updatedAt;

  // ============================================
  // GETTERS DE CONVENIÊNCIA
  // ============================================

  /// Verifica se está vinculado a uma academia
  bool get hasAcademy => academyId != null && academyId!.isNotEmpty;

  /// Verifica se está aprovado na academia
  bool get isApprovedInAcademy => academyStatus == AcademyStatus.approved;

  /// Verifica se é owner de uma academia
  bool get isOwner => role == UserRole.owner;

  /// Verifica se é mestre de alguma modalidade
  bool get isModalityMaster => role == UserRole.modalityMaster;

  /// Verifica se é professor
  bool get isTeacher => role == UserRole.teacher;

  /// Verifica se é instrutor
  bool get isInstructor => role == UserRole.instructor;

  /// Verifica se é aluno
  bool get isStudent => role == UserRole.student;

  /// Verifica se pode fazer check-in (pagamento em dia)
  bool get canCheckIn =>
      paymentStatus == null ||
      paymentStatus == PaymentStatus.active ||
      paymentStatus == PaymentStatus.exempt;

  /// Retorna a arte marcial atual (para exibição)
  /// Se tem modalidades, retorna a primeira; senão usa o campo legado
  MartialArt get martialArt {
    if (enrolledModalities.isNotEmpty) {
      return enrolledModalities.first.martialArt;
    }
    if (martialArtType == null) {
      return MartialArtsConfig.defaultArt;
    }
    return MartialArtsConfig.getByType(martialArtType!);
  }

  /// Retorna a faixa atual (para exibição principal)
  Belt? get currentBelt {
    if (enrolledModalities.isNotEmpty) {
      return enrolledModalities.first.currentBelt;
    }
    if (graduation == null) return martialArt.initialBelt;
    return martialArt.getBeltById(graduation!.beltId);
  }

  /// Retorna a próxima faixa
  Belt? get nextBelt {
    if (enrolledModalities.isNotEmpty) {
      return enrolledModalities.first.nextBelt;
    }
    final current = currentBelt;
    if (current == null) return null;
    return martialArt.getNextBelt(current);
  }

  /// Calcula aulas restantes para próxima graduação
  int get classesUntilPromotion {
    if (enrolledModalities.isNotEmpty) {
      final modality = enrolledModalities.first;
      final next = modality.nextBelt;
      if (next == null) return 0;
      final remaining =
          next.minClassesForPromotion - modality.graduation.classesAtCurrentBelt;
      return remaining > 0 ? remaining : 0;
    }
    final next = nextBelt;
    if (next == null || graduation == null) return 0;
    final remaining =
        next.minClassesForPromotion - graduation!.classesAtCurrentBelt;
    return remaining > 0 ? remaining : 0;
  }

  /// Retorna total de aulas (soma de todas modalidades ou legado)
  int get totalClassesAll {
    if (enrolledModalities.isNotEmpty) {
      return enrolledModalities.fold(0, (sum, m) => sum + m.totalClasses);
    }
    return totalClasses;
  }

  /// Calcula tempo de treino
  Duration? get trainingTime {
    if (startDate == null) return null;
    return DateTime.now().difference(startDate!);
  }

  /// Retorna modalidade por tipo
  StudentModality? getEnrolledModality(MartialArtType type) {
    try {
      return enrolledModalities.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Verifica se está matriculado em uma modalidade
  bool isEnrolledIn(MartialArtType type) =>
      enrolledModalities.any((m) => m.type == type);

  /// Perfil vazio
  static const empty = UserProfile(id: '', email: '');

  /// Verifica se o perfil está vazio
  bool get isEmpty => this == empty;
  bool get isNotEmpty => !isEmpty;

  /// Converte para Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      // Academia
      'academyId': academyId,
      'academyStatus': academyStatus?.name,
      'managedModalities': managedModalities?.map((m) => m.name).toList(),
      'enrolledModalities': enrolledModalities.map((m) => m.toMap()).toList(),
      'planId': planId,
      'joinedAcademyAt': joinedAcademyAt?.toIso8601String(),
      'paymentStatus': paymentStatus?.name,
      'paymentDueDate': paymentDueDate?.toIso8601String(),
      // Legado
      'martialArtType': martialArtType?.name,
      'graduation': graduation?.toMap(),
      'graduationHistory': graduationHistory.map((g) => g.toMap()).toList(),
      'academyName': academyName,
      'instructorName': instructorName,
      'startDate': startDate?.toIso8601String(),
      'weightCategory': weightCategory,
      'competitions': competitions.map((c) => c.toMap()).toList(),
      'totalClasses': totalClasses,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Cria a partir de Map (do Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      // Academia
      academyId: map['academyId'] as String?,
      academyStatus: map['academyStatus'] != null
          ? AcademyStatus.values.firstWhere(
              (s) => s.name == map['academyStatus'],
              orElse: () => AcademyStatus.pending,
            )
          : null,
      managedModalities: (map['managedModalities'] as List<dynamic>?)
          ?.map((m) => MartialArtType.values.firstWhere(
                (t) => t.name == m,
                orElse: () => MartialArtType.jiuJitsu,
              ))
          .toList(),
      enrolledModalities: (map['enrolledModalities'] as List<dynamic>?)
              ?.map((m) => StudentModality.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      planId: map['planId'] as String?,
      joinedAcademyAt: map['joinedAcademyAt'] != null
          ? DateTime.parse(map['joinedAcademyAt'] as String)
          : null,
      paymentStatus: map['paymentStatus'] != null
          ? PaymentStatus.values.firstWhere(
              (s) => s.name == map['paymentStatus'],
              orElse: () => PaymentStatus.pending,
            )
          : null,
      paymentDueDate: map['paymentDueDate'] != null
          ? DateTime.parse(map['paymentDueDate'] as String)
          : null,
      // Legado
      martialArtType: map['martialArtType'] != null
          ? MartialArtType.values.firstWhere(
              (t) => t.name == map['martialArtType'],
              orElse: () => MartialArtType.jiuJitsu,
            )
          : null,
      graduation: map['graduation'] != null
          ? UserGraduation.fromMap(map['graduation'] as Map<String, dynamic>)
          : null,
      graduationHistory: (map['graduationHistory'] as List<dynamic>?)
              ?.map((g) => GraduationHistory.fromMap(g as Map<String, dynamic>))
              .toList() ??
          [],
      academyName: map['academyName'] as String? ?? map['academy'] as String?,
      instructorName:
          map['instructorName'] as String? ?? map['instructor'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      weightCategory: map['weightCategory'] as String?,
      competitions: (map['competitions'] as List<dynamic>?)
              ?.map((c) => Competition.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      totalClasses: map['totalClasses'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Cria cópia com valores alterados
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? academyId,
    AcademyStatus? academyStatus,
    List<MartialArtType>? managedModalities,
    List<StudentModality>? enrolledModalities,
    String? planId,
    DateTime? joinedAcademyAt,
    PaymentStatus? paymentStatus,
    DateTime? paymentDueDate,
    MartialArtType? martialArtType,
    UserGraduation? graduation,
    List<GraduationHistory>? graduationHistory,
    String? academyName,
    String? instructorName,
    DateTime? startDate,
    String? weightCategory,
    List<Competition>? competitions,
    int? totalClasses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      academyId: academyId ?? this.academyId,
      academyStatus: academyStatus ?? this.academyStatus,
      managedModalities: managedModalities ?? this.managedModalities,
      enrolledModalities: enrolledModalities ?? this.enrolledModalities,
      planId: planId ?? this.planId,
      joinedAcademyAt: joinedAcademyAt ?? this.joinedAcademyAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      martialArtType: martialArtType ?? this.martialArtType,
      graduation: graduation ?? this.graduation,
      graduationHistory: graduationHistory ?? this.graduationHistory,
      academyName: academyName ?? this.academyName,
      instructorName: instructorName ?? this.instructorName,
      startDate: startDate ?? this.startDate,
      weightCategory: weightCategory ?? this.weightCategory,
      competitions: competitions ?? this.competitions,
      totalClasses: totalClasses ?? this.totalClasses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        role,
        academyId,
        academyStatus,
        managedModalities,
        enrolledModalities,
        planId,
        joinedAcademyAt,
        paymentStatus,
        paymentDueDate,
        martialArtType,
        graduation,
        graduationHistory,
        academyName,
        instructorName,
        startDate,
        weightCategory,
        competitions,
        totalClasses,
        createdAt,
        updatedAt,
      ];
}

/// Modelo de Competição
class Competition extends Equatable {
  const Competition({
    required this.name,
    required this.date,
    this.location,
    this.category,
    this.result,
    this.medal,
    this.modalityType,
  });

  final String name;
  final DateTime date;
  final String? location;
  final String? category;
  final String? result;
  final String? medal;
  final MartialArtType? modalityType;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'location': location,
      'category': category,
      'result': result,
      'medal': medal,
      'modalityType': modalityType?.name,
    };
  }

  factory Competition.fromMap(Map<String, dynamic> map) {
    return Competition(
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String?,
      category: map['category'] as String?,
      result: map['result'] as String?,
      medal: map['medal'] as String?,
      modalityType: map['modalityType'] != null
          ? MartialArtType.values.firstWhere(
              (t) => t.name == map['modalityType'],
              orElse: () => MartialArtType.jiuJitsu,
            )
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [name, date, location, category, result, medal, modalityType];
}
