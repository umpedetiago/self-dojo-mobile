import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Modelo de Faixa/Graduação
class Belt extends Equatable {
  const Belt({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    required this.maxDegrees,
    required this.minClassesForPromotion,
    this.secondaryColor,
    this.minMonthsAtBelt,
    this.hasBlackTip = false,
    this.degreeMarkColor,
    this.tipColor,
  });

  /// ID único da faixa
  final String id;

  /// Nome da faixa (ex: "Faixa Azul")
  final String name;

  /// Cor principal da faixa
  final Color color;

  /// Cor secundária (para faixas como coral)
  final Color? secondaryColor;

  /// Ordem da faixa (0 = primeira)
  final int order;

  /// Número máximo de graus nesta faixa
  final int maxDegrees;

  /// Número mínimo de aulas para promoção à próxima faixa
  final int minClassesForPromotion;

  /// Tempo mínimo (em meses) nesta faixa antes de promoção
  final int? minMonthsAtBelt;

  /// Se a faixa tem ponteira (padrão BJJ)
  final bool hasBlackTip;

  /// Cor das marcas de grau (se null, usa contraste automático)
  final Color? degreeMarkColor;

  /// Cor da ponteira (se null e hasBlackTip=true, usa preto)
  final Color? tipColor;

  /// Verifica se a faixa tem graus
  bool get hasDegrees => maxDegrees > 0;

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        secondaryColor,
        order,
        maxDegrees,
        minClassesForPromotion,
        minMonthsAtBelt,
        hasBlackTip,
        degreeMarkColor,
        tipColor,
      ];

  @override
  String toString() => 'Belt($name)';
}

/// Graduação do usuário (faixa + grau atual)
class UserGraduation extends Equatable {
  const UserGraduation({
    required this.beltId,
    this.degree = 0,
    this.promotionDate,
    this.classesAtCurrentBelt = 0,
    this.hasAparadores,
  });

  /// ID da faixa atual
  final String beltId;

  /// Grau atual na faixa (0 = sem grau)
  final int degree;

  /// Data da última promoção
  final DateTime? promotionDate;

  /// Número de aulas desde a última promoção
  final int classesAtCurrentBelt;

  /// Se tem aparadores na faixa preta (null = usar padrão: true se tem graus)
  final bool? hasAparadores;

  /// Retorna se deve mostrar aparadores
  /// - Se tem graus > 0: sempre mostra
  /// - Se graus = 0: usa o valor de hasAparadores (padrão false)
  bool get showAparadores => degree > 0 || (hasAparadores ?? false);

  /// Cria uma graduação inicial (faixa branca, sem grau)
  factory UserGraduation.initial(String initialBeltId) {
    return UserGraduation(
      beltId: initialBeltId,
      degree: 0,
      promotionDate: DateTime.now(),
      classesAtCurrentBelt: 0,
    );
  }

  /// Converte para Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'beltId': beltId,
      'degree': degree,
      'promotionDate': promotionDate?.toIso8601String(),
      'classesAtCurrentBelt': classesAtCurrentBelt,
      'hasAparadores': hasAparadores,
    };
  }

  /// Cria a partir de Map (do Firestore)
  factory UserGraduation.fromMap(Map<String, dynamic> map) {
    return UserGraduation(
      beltId: map['beltId'] as String,
      degree: map['degree'] as int? ?? 0,
      promotionDate: map['promotionDate'] != null
          ? DateTime.parse(map['promotionDate'] as String)
          : null,
      classesAtCurrentBelt: map['classesAtCurrentBelt'] as int? ?? 0,
      hasAparadores: map['hasAparadores'] as bool?,
    );
  }

  /// Cria cópia com valores alterados
  UserGraduation copyWith({
    String? beltId,
    int? degree,
    DateTime? promotionDate,
    int? classesAtCurrentBelt,
    bool? hasAparadores,
  }) {
    return UserGraduation(
      beltId: beltId ?? this.beltId,
      degree: degree ?? this.degree,
      promotionDate: promotionDate ?? this.promotionDate,
      classesAtCurrentBelt: classesAtCurrentBelt ?? this.classesAtCurrentBelt,
      hasAparadores: hasAparadores ?? this.hasAparadores,
    );
  }

  @override
  List<Object?> get props => [beltId, degree, promotionDate, classesAtCurrentBelt, hasAparadores];
}

/// Histórico de graduações
class GraduationHistory extends Equatable {
  const GraduationHistory({
    required this.beltId,
    required this.degree,
    required this.date,
    this.notes,
  });

  final String beltId;
  final int degree;
  final DateTime date;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'beltId': beltId,
      'degree': degree,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory GraduationHistory.fromMap(Map<String, dynamic> map) {
    return GraduationHistory(
      beltId: map['beltId'] as String,
      degree: map['degree'] as int? ?? 0,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [beltId, degree, date, notes];
}

