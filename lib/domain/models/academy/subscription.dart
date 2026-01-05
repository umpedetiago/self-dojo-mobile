import 'package:equatable/equatable.dart';

/// Status da assinatura do app
enum SubscriptionStatus {
  /// Em período de teste (7 dias)
  trial,

  /// Assinatura ativa
  active,

  /// Pagamento atrasado
  pastDue,

  /// Cancelada
  cancelled,

  /// Trial expirado sem conversão
  expired,
}

/// Extensão para SubscriptionStatus
extension SubscriptionStatusExtension on SubscriptionStatus {
  String get displayName {
    switch (this) {
      case SubscriptionStatus.trial:
        return 'Período de Teste';
      case SubscriptionStatus.active:
        return 'Ativo';
      case SubscriptionStatus.pastDue:
        return 'Pagamento Atrasado';
      case SubscriptionStatus.cancelled:
        return 'Cancelado';
      case SubscriptionStatus.expired:
        return 'Expirado';
    }
  }

  bool get isActive =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.trial;
}

/// Planos de assinatura do app disponíveis
enum SubscriptionPlan {
  /// Plano básico
  basic,

  /// Plano profissional
  pro,

  /// Plano empresarial
  enterprise,
}

/// Configuração de cada plano de assinatura
class SubscriptionPlanConfig {
  const SubscriptionPlanConfig({
    required this.plan,
    required this.name,
    required this.maxStudents,
    required this.maxTeachers,
    required this.maxModalities,
    required this.monthlyPrice,
    required this.features,
  });

  final SubscriptionPlan plan;
  final String name;
  final int maxStudents;
  final int maxTeachers;
  final int maxModalities;
  final double monthlyPrice;
  final List<String> features;

  /// Configurações padrão dos planos
  static const Map<SubscriptionPlan, SubscriptionPlanConfig> defaults = {
    SubscriptionPlan.basic: SubscriptionPlanConfig(
      plan: SubscriptionPlan.basic,
      name: 'Basic',
      maxStudents: 50,
      maxTeachers: 3,
      maxModalities: 2,
      monthlyPrice: 99.90,
      features: [
        'Até 50 alunos',
        'Até 3 professores',
        'Até 2 modalidades',
        'Check-in de presença',
        'Controle de graduações',
        'Relatórios básicos',
      ],
    ),
    SubscriptionPlan.pro: SubscriptionPlanConfig(
      plan: SubscriptionPlan.pro,
      name: 'Pro',
      maxStudents: 200,
      maxTeachers: 10,
      maxModalities: 5,
      monthlyPrice: 199.90,
      features: [
        'Até 200 alunos',
        'Até 10 professores',
        'Até 5 modalidades',
        'Tudo do Basic',
        'Controle financeiro',
        'Relatórios avançados',
        'Suporte prioritário',
      ],
    ),
    SubscriptionPlan.enterprise: SubscriptionPlanConfig(
      plan: SubscriptionPlan.enterprise,
      name: 'Enterprise',
      maxStudents: -1, // Ilimitado
      maxTeachers: -1,
      maxModalities: -1,
      monthlyPrice: 399.90,
      features: [
        'Alunos ilimitados',
        'Professores ilimitados',
        'Modalidades ilimitadas',
        'Tudo do Pro',
        'API de integração',
        'Suporte dedicado',
        'Customizações',
      ],
    ),
  };

  /// Retorna config de um plano
  static SubscriptionPlanConfig getConfig(SubscriptionPlan plan) =>
      defaults[plan]!;

  /// Verifica se está dentro do limite
  bool isWithinLimits({
    required int students,
    required int teachers,
    required int modalities,
  }) {
    if (maxStudents != -1 && students > maxStudents) return false;
    if (maxTeachers != -1 && teachers > maxTeachers) return false;
    if (maxModalities != -1 && modalities > maxModalities) return false;
    return true;
  }
}

/// Informações da assinatura da academia
class SubscriptionInfo extends Equatable {
  const SubscriptionInfo({
    required this.plan,
    required this.status,
    required this.startDate,
    this.endDate,
    this.isTrial = false,
    this.trialStartDate,
    this.trialEndDate,
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;

  /// Trial
  final bool isTrial;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;

  /// Duração do trial em dias
  static const int trialDurationDays = 7;

  /// Limite de alunos durante trial
  static const int trialMaxStudents = 10;

  /// Cria uma assinatura em modo trial
  factory SubscriptionInfo.trial() {
    final now = DateTime.now();
    return SubscriptionInfo(
      plan: SubscriptionPlan.pro, // Trial tem acesso ao Pro
      status: SubscriptionStatus.trial,
      startDate: now,
      isTrial: true,
      trialStartDate: now,
      trialEndDate: now.add(const Duration(days: trialDurationDays)),
    );
  }

  /// Retorna a configuração do plano
  SubscriptionPlanConfig get planConfig =>
      SubscriptionPlanConfig.getConfig(plan);

  /// Limite de alunos (considerando trial)
  int get maxStudents =>
      isTrial ? trialMaxStudents : planConfig.maxStudents;

  /// Limite de professores
  int get maxTeachers => planConfig.maxTeachers;

  /// Limite de modalidades
  int get maxModalities => planConfig.maxModalities;

  /// Dias restantes do trial
  int get trialDaysRemaining {
    if (!isTrial || trialEndDate == null) return 0;
    final remaining = trialEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se o trial expirou
  bool get isTrialExpired {
    if (!isTrial || trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  /// Converte para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'plan': plan.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isTrial': isTrial,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
    };
  }

  /// Cria a partir de Map (Firestore)
  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == map['plan'],
        orElse: () => SubscriptionPlan.basic,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      isTrial: map['isTrial'] as bool? ?? false,
      trialStartDate: map['trialStartDate'] != null
          ? DateTime.parse(map['trialStartDate'] as String)
          : null,
      trialEndDate: map['trialEndDate'] != null
          ? DateTime.parse(map['trialEndDate'] as String)
          : null,
    );
  }

  /// Copia com alterações
  SubscriptionInfo copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? isTrial,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
  }) {
    return SubscriptionInfo(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isTrial: isTrial ?? this.isTrial,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
    );
  }

  @override
  List<Object?> get props => [
        plan,
        status,
        startDate,
        endDate,
        isTrial,
        trialStartDate,
        trialEndDate,
      ];
}

