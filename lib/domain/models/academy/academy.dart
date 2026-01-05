import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/subscription.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Modelo principal da Academia
class Academy extends Equatable {
  const Academy({
    required this.id,
    required this.name,
    required this.ownerId,
    this.logoUrl,
    this.description,
    this.address,
    this.city,
    this.state,
    this.phone,
    this.email,
    this.website,
    this.modalities = const [],
    this.financialConfig,
    this.subscription,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// ID único da academia
  final String id;

  /// Nome da academia
  final String name;

  /// ID do dono/responsável (Owner)
  final String ownerId;

  /// URL do logo
  final String? logoUrl;

  /// Descrição da academia
  final String? description;

  /// Endereço
  final String? address;

  /// Cidade
  final String? city;

  /// Estado
  final String? state;

  /// Telefone
  final String? phone;

  /// Email
  final String? email;

  /// Website
  final String? website;

  /// Modalidades oferecidas
  final List<AcademyModality> modalities;

  /// Configurações financeiras (planos para alunos)
  final FinancialConfig? financialConfig;

  /// Assinatura do app
  final SubscriptionInfo? subscription;

  /// Se a academia está ativa
  final bool isActive;

  /// Data de criação
  final DateTime? createdAt;

  /// Data da última atualização
  final DateTime? updatedAt;

  /// Academia vazia
  static const empty = Academy(id: '', name: '', ownerId: '');

  /// Verifica se está vazia
  bool get isEmpty => this == empty;
  bool get isNotEmpty => !isEmpty;

  /// Retorna lista de tipos de modalidades
  List<MartialArtType> get modalityTypes =>
      modalities.map((m) => m.type).toList();

  /// Retorna modalidade por tipo
  AcademyModality? getModality(MartialArtType type) {
    try {
      return modalities.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Verifica se oferece uma modalidade
  bool hasModality(MartialArtType type) =>
      modalities.any((m) => m.type == type && m.isActive);

  /// Verifica se o usuário é o owner
  bool isOwner(String userId) => ownerId == userId;

  /// Verifica se o usuário é mestre de alguma modalidade
  bool isModalityMaster(String userId) =>
      modalities.any((m) => m.masterId == userId);

  /// Verifica se o usuário é professor em alguma modalidade
  bool isTeacher(String userId) =>
      modalities.any((m) => m.teacherIds.contains(userId));

  /// Verifica se o usuário é instrutor em alguma modalidade
  bool isInstructor(String userId) =>
      modalities.any((m) => m.instructorIds.contains(userId));

  /// Verifica se o usuário faz parte da equipe
  bool isStaff(String userId) =>
      isOwner(userId) ||
      isModalityMaster(userId) ||
      isTeacher(userId) ||
      isInstructor(userId);

  /// Total de professores (todas modalidades)
  int get totalTeachers {
    final allTeachers = <String>{};
    for (final modality in modalities) {
      if (modality.masterId != null) allTeachers.add(modality.masterId!);
      allTeachers.addAll(modality.teacherIds);
    }
    return allTeachers.length;
  }

  /// Verifica se está dentro dos limites da assinatura
  bool canAddStudent(int currentStudents) {
    if (subscription == null) return false;
    final max = subscription!.maxStudents;
    return max == -1 || currentStudents < max;
  }

  bool canAddTeacher() {
    if (subscription == null) return false;
    final max = subscription!.maxTeachers;
    return max == -1 || totalTeachers < max;
  }

  bool canAddModality() {
    if (subscription == null) return false;
    final max = subscription!.maxModalities;
    return max == -1 || modalities.length < max;
  }

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'logoUrl': logoUrl,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'phone': phone,
      'email': email,
      'website': website,
      'modalities': modalities.map((m) => m.toMap()).toList(),
      'financialConfig': financialConfig?.toMap(),
      'subscription': subscription?.toMap(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Cria a partir de Map (Firestore)
  factory Academy.fromMap(Map<String, dynamic> map) {
    return Academy(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      logoUrl: map['logoUrl'] as String?,
      description: map['description'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      modalities: (map['modalities'] as List<dynamic>?)
              ?.map((m) => AcademyModality.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      financialConfig: map['financialConfig'] != null
          ? FinancialConfig.fromMap(
              map['financialConfig'] as Map<String, dynamic>)
          : null,
      subscription: map['subscription'] != null
          ? SubscriptionInfo.fromMap(map['subscription'] as Map<String, dynamic>)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Copia com alterações
  Academy copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? logoUrl,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? email,
    String? website,
    List<AcademyModality>? modalities,
    FinancialConfig? financialConfig,
    SubscriptionInfo? subscription,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Academy(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      modalities: modalities ?? this.modalities,
      financialConfig: financialConfig ?? this.financialConfig,
      subscription: subscription ?? this.subscription,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        logoUrl,
        description,
        address,
        city,
        state,
        phone,
        email,
        website,
        modalities,
        financialConfig,
        subscription,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Configuração financeira da academia (planos para alunos)
class FinancialConfig extends Equatable {
  const FinancialConfig({
    required this.plans,
    this.paymentDueDay = 10,
    this.enrollmentFee,
    this.annualFee,
  });

  /// Planos disponíveis
  final List<StudentPlanConfig> plans;

  /// Dia do vencimento (1-28)
  final int paymentDueDay;

  /// Taxa de matrícula
  final double? enrollmentFee;

  /// Taxa anual
  final double? annualFee;

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'plans': plans.map((p) => p.toMap()).toList(),
      'paymentDueDay': paymentDueDay,
      'enrollmentFee': enrollmentFee,
      'annualFee': annualFee,
    };
  }

  /// Cria a partir de Map (Firestore)
  factory FinancialConfig.fromMap(Map<String, dynamic> map) {
    return FinancialConfig(
      plans: (map['plans'] as List<dynamic>?)
              ?.map((p) => StudentPlanConfig.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      paymentDueDay: map['paymentDueDay'] as int? ?? 10,
      enrollmentFee: (map['enrollmentFee'] as num?)?.toDouble(),
      annualFee: (map['annualFee'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [plans, paymentDueDay, enrollmentFee, annualFee];
}

/// Tipo de plano do aluno (quantidade de modalidades)
enum StudentPlanType {
  /// 1 modalidade
  single,

  /// 2 modalidades
  duo,

  /// Todas as modalidades
  full,
}

/// Extensão para StudentPlanType
extension StudentPlanTypeExtension on StudentPlanType {
  String get displayName {
    switch (this) {
      case StudentPlanType.single:
        return 'Single';
      case StudentPlanType.duo:
        return 'Duo';
      case StudentPlanType.full:
        return 'Full';
    }
  }

  String get description {
    switch (this) {
      case StudentPlanType.single:
        return '1 modalidade';
      case StudentPlanType.duo:
        return '2 modalidades';
      case StudentPlanType.full:
        return 'Todas as modalidades';
    }
  }

  int get maxModalities {
    switch (this) {
      case StudentPlanType.single:
        return 1;
      case StudentPlanType.duo:
        return 2;
      case StudentPlanType.full:
        return -1; // Ilimitado
    }
  }
}

/// Configuração de plano para alunos
class StudentPlanConfig extends Equatable {
  const StudentPlanConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.durationMonths = 1,
    this.discount,
    this.includedModalities,
    this.benefits = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final StudentPlanType type;
  final double price;
  final int durationMonths;
  final double? discount;
  final List<MartialArtType>? includedModalities;
  final List<String> benefits;
  final bool isActive;

  /// Máximo de modalidades permitidas
  int get maxModalities =>
      includedModalities?.length ?? type.maxModalities;

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'price': price,
      'durationMonths': durationMonths,
      'discount': discount,
      'includedModalities': includedModalities?.map((m) => m.name).toList(),
      'benefits': benefits,
      'isActive': isActive,
    };
  }

  /// Cria a partir de Map (Firestore)
  factory StudentPlanConfig.fromMap(Map<String, dynamic> map) {
    return StudentPlanConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      type: StudentPlanType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => StudentPlanType.single,
      ),
      price: (map['price'] as num).toDouble(),
      durationMonths: map['durationMonths'] as int? ?? 1,
      discount: (map['discount'] as num?)?.toDouble(),
      includedModalities: (map['includedModalities'] as List<dynamic>?)
          ?.map((m) => MartialArtType.values.firstWhere(
                (t) => t.name == m,
                orElse: () => MartialArtType.jiuJitsu,
              ))
          .toList(),
      benefits: (map['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        price,
        durationMonths,
        discount,
        includedModalities,
        benefits,
        isActive,
      ];
}

