import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';

/// Tipo de arte marcial
enum MartialArtType {
  jiuJitsu,
  jiuJitsuKids,
  judo,
  karate,
  muayThai,
  boxe,
  taekwondo,
  mma,
  kickboxing,
}

/// Modelo de Arte Marcial
class MartialArt extends Equatable {
  const MartialArt({
    required this.type,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.primaryColor,
    required this.belts,
    this.description,
  });

  final MartialArtType type;
  final String name;
  final String shortName;
  final IconData icon;
  final Color primaryColor;
  final List<Belt>? belts;
  final String? description;

  /// Retorna a faixa inicial
  Belt? get initialBelt => belts?.first;

  /// Retorna a próxima faixa baseada na atual
  Belt? getNextBelt(Belt currentBelt) {
    if (belts == null) return null;
    final currentIndex = belts!.indexWhere((b) => b.id == currentBelt.id);
    if (currentIndex == -1 || currentIndex >= belts!.length - 1 ) {
      return null;
    }
    return belts![currentIndex + 1];
  }

  /// Retorna uma faixa pelo ID
  Belt? getBeltById(String beltId) {
    try {
      return belts?.firstWhere((b) => b.id == beltId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [type, name, belts];
}

/// Configuração de todas as artes marciais disponíveis
class MartialArtsConfig {
  MartialArtsConfig._();

  /// Retorna todas as artes marciais
  static List<MartialArt> get all =>
      MartialArtType.values.map(_buildDefaultArt).toList();

  /// Retorna uma arte marcial pelo tipo
  static MartialArt getByType(MartialArtType type) => _buildDefaultArt(type);

  /// Arte marcial padrão (Jiu-Jitsu)
  static MartialArt get defaultArt => getByType(MartialArtType.jiuJitsu);

  /// Retorna uma arte marcial pelo nome do tipo (para Firestore)
  static MartialArt? getByTypeName(String typeName) {
    try {
      final type = MartialArtType.values.firstWhere(
        (t) => t.name == typeName,
      );
      return getByType(type);
    } catch (_) {
      return null;
    }
  }

  /// Versão atual usa uma configuração padrão em código.
  /// Em uma próxima etapa podemos popular a partir da API.
  static MartialArt _buildDefaultArt(MartialArtType type) {
    // Faixa branca genérica como fallback seguro
    final whiteBelt = Belt(
      id: '${type.name}_white',
      name: 'Faixa Branca',
      color: Colors.white,
      order: 0,
      maxDegrees: 4,
      minMonthsAtBelt: 0,
    );

    switch (type) {
      case MartialArtType.jiuJitsu:
      case MartialArtType.jiuJitsuKids:
        return MartialArt(
          type: type,
          name: type == MartialArtType.jiuJitsu
              ? 'Jiu-Jitsu Brasileiro'
              : 'Jiu-Jitsu Kids',
          shortName: 'Jiu-Jitsu',
          icon: Icons.sports_martial_arts,
          primaryColor: const Color(0xFF6366F1),
          belts: [whiteBelt],
          description: 'Arte suave focada em alavancas e finalizações.',
        );
      case MartialArtType.judo:
        return MartialArt(
          type: type,
          name: 'Judô',
          shortName: 'Judô',
          icon: Icons.sports_martial_arts,
          primaryColor: const Color(0xFF10B981),
          belts: [whiteBelt],
        );
      case MartialArtType.karate:
        return MartialArt(
          type: type,
          name: 'Karatê',
          shortName: 'Karatê',
          icon: Icons.sports_kabaddi,
          primaryColor: const Color(0xFFF59E0B),
          belts: [whiteBelt],
        );
      case MartialArtType.muayThai:
        return MartialArt(
          type: type,
          name: 'Muay Thai',
          shortName: 'Muay Thai',
          icon: Icons.sports_mma,
          primaryColor: const Color(0xFFEF4444),
          belts: [whiteBelt],
        );
      case MartialArtType.boxe:
        return MartialArt(
          type: type,
          name: 'Boxe',
          shortName: 'Boxe',
          icon: Icons.sports_mma,
          primaryColor: const Color(0xFF3B82F6),
          belts: [whiteBelt],
        );
      case MartialArtType.taekwondo:
        return MartialArt(
          type: type,
          name: 'Taekwondo',
          shortName: 'Taekwondo',
          icon: Icons.sports_kabaddi,
          primaryColor: const Color(0xFF8B5CF6),
          belts: [whiteBelt],
        );
      case MartialArtType.mma:
        return MartialArt(
          type: type,
          name: 'MMA',
          shortName: 'MMA',
          icon: Icons.sports_mma,
          primaryColor: const Color(0xFF111827),
          belts: [whiteBelt],
        );
      case MartialArtType.kickboxing:
        return MartialArt(
          type: type,
          name: 'Kickboxing',
          shortName: 'Kickboxing',
          icon: Icons.sports_mma,
          primaryColor: const Color(0xFFEC4899),
          belts: [whiteBelt],
        );
    }
  }
}