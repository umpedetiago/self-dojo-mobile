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
  final List<Belt> belts;
  final String? description;

  /// Retorna a faixa inicial
  Belt get initialBelt => belts.first;

  /// Retorna a próxima faixa baseada na atual
  Belt? getNextBelt(Belt currentBelt) {
    final currentIndex = belts.indexWhere((b) => b.id == currentBelt.id);
    if (currentIndex == -1 || currentIndex >= belts.length - 1) {
      return null;
    }
    return belts[currentIndex + 1];
  }

  /// Retorna uma faixa pelo ID
  Belt? getBeltById(String beltId) {
    try {
      return belts.firstWhere((b) => b.id == beltId);
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

  static final Map<MartialArtType, MartialArt> _arts = {
    MartialArtType.jiuJitsu: _jiuJitsu,
    MartialArtType.jiuJitsuKids: _jiuJitsuKids,
    MartialArtType.judo: _judo,
    MartialArtType.karate: _karate,
    MartialArtType.muayThai: _muayThai,
    MartialArtType.boxe: _boxe,
    MartialArtType.taekwondo: _taekwondo,
    MartialArtType.mma: _mma,
    MartialArtType.kickboxing: _kickboxing,
  };

  /// Retorna todas as artes marciais
  static List<MartialArt> get all => _arts.values.toList();

  /// Retorna uma arte marcial pelo tipo
  static MartialArt getByType(MartialArtType type) => _arts[type]!;

  /// Arte marcial padrão (Jiu-Jitsu)
  static MartialArt get defaultArt => _jiuJitsu;

  /// Retorna uma arte marcial pelo nome do tipo (para Firestore)
  static MartialArt? getByTypeName(String typeName) {
    try {
      final type = MartialArtType.values.firstWhere(
        (t) => t.name == typeName,
      );
      return _arts[type];
    } catch (_) {
      return null;
    }
  }

  // ============================================
  // JIU-JITSU BRASILEIRO
  // ============================================
  static final _jiuJitsu = MartialArt(
    type: MartialArtType.jiuJitsu,
    name: 'Jiu-Jitsu Brasileiro',
    shortName: 'BJJ',
    icon: Icons.sports_martial_arts,
    primaryColor: const Color(0xFF1E3A5F),
    description: 'Arte marcial focada em técnicas de solo e finalização',
    belts: [
      const Belt(
        id: 'bjj_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 4,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'bjj_blue',
        name: 'Faixa Azul',
        color: Color(0xFF1565C0),
        order: 1,
        maxDegrees: 4,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 24,
      ),
      const Belt(
        id: 'bjj_purple',
        name: 'Faixa Roxa',
        color: Color(0xFF7B1FA2),
        order: 2,
        maxDegrees: 4,
        minClassesForPromotion: 150,
        minMonthsAtBelt: 18,
      ),
      const Belt(
        id: 'bjj_brown',
        name: 'Faixa Marrom',
        color: Color(0xFF5D4037),
        order: 3,
        maxDegrees: 4,
        minClassesForPromotion: 150,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'bjj_black',
        name: 'Faixa Preta',
        color: Colors.black,
        order: 4,
        maxDegrees: 6,
        minClassesForPromotion: 200,
        minMonthsAtBelt: 36,
      ),
      const Belt(
        id: 'bjj_red_black',
        name: 'Faixa Coral',
        color: Color(0xFFC62828),
        secondaryColor: Colors.black,
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 0,
        minMonthsAtBelt: 84,
      ),
      const Belt(
        id: 'bjj_red',
        name: 'Faixa Vermelha',
        color: Color(0xFFC62828),
        order: 6,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
    ],
  );

  // ============================================
  // JIU-JITSU INFANTIL (4-15 anos)
  // Sistema de graduação IBJJF para crianças
  // ============================================
  static final _jiuJitsuKids = MartialArt(
    type: MartialArtType.jiuJitsuKids,
    name: 'Jiu-Jitsu Infantil',
    shortName: 'BJJ Kids',
    icon: Icons.sports_martial_arts,
    primaryColor: const Color(0xFF1E3A5F),
    description: 'Sistema de graduação infantil do BJJ (4-15 anos)',
    belts: [
      // Faixa Branca
      const Belt(
        id: 'bjj_kids_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 4,
        minClassesForPromotion: 0,
      ),
      // Faixas Cinza (Cinza Branca, Cinza, Cinza Preta)
      const Belt(
        id: 'bjj_kids_grey_white',
        name: 'Faixa Cinza e Branca',
        color: Color(0xFF9E9E9E),
        secondaryColor: Colors.white,
        order: 1,
        maxDegrees: 4,
        minClassesForPromotion: 30,
        minMonthsAtBelt: 4,
      ),
      const Belt(
        id: 'bjj_kids_grey',
        name: 'Faixa Cinza',
        color: Color(0xFF9E9E9E),
        order: 2,
        maxDegrees: 4,
        minClassesForPromotion: 40,
        minMonthsAtBelt: 4,
      ),
      const Belt(
        id: 'bjj_kids_grey_black',
        name: 'Faixa Cinza e Preta',
        color: Color(0xFF9E9E9E),
        secondaryColor: Colors.black,
        order: 3,
        maxDegrees: 4,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 4,
      ),
      // Faixas Amarela (Amarela Branca, Amarela, Amarela Preta)
      const Belt(
        id: 'bjj_kids_yellow_white',
        name: 'Faixa Amarela e Branca',
        color: Color(0xFFFDD835),
        secondaryColor: Colors.white,
        order: 4,
        maxDegrees: 4,
        minClassesForPromotion: 60,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'bjj_kids_yellow',
        name: 'Faixa Amarela',
        color: Color(0xFFFDD835),
        order: 5,
        maxDegrees: 4,
        minClassesForPromotion: 70,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'bjj_kids_yellow_black',
        name: 'Faixa Amarela e Preta',
        color: Color(0xFFFDD835),
        secondaryColor: Colors.black,
        order: 6,
        maxDegrees: 4,
        minClassesForPromotion: 80,
        minMonthsAtBelt: 6,
      ),
      // Faixas Laranja (Laranja Branca, Laranja, Laranja Preta)
      const Belt(
        id: 'bjj_kids_orange_white',
        name: 'Faixa Laranja e Branca',
        color: Color(0xFFFF9800),
        secondaryColor: Colors.white,
        order: 7,
        maxDegrees: 4,
        minClassesForPromotion: 90,
        minMonthsAtBelt: 8,
      ),
      const Belt(
        id: 'bjj_kids_orange',
        name: 'Faixa Laranja',
        color: Color(0xFFFF9800),
        order: 8,
        maxDegrees: 4,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 8,
      ),
      const Belt(
        id: 'bjj_kids_orange_black',
        name: 'Faixa Laranja e Preta',
        color: Color(0xFFFF9800),
        secondaryColor: Colors.black,
        order: 9,
        maxDegrees: 4,
        minClassesForPromotion: 110,
        minMonthsAtBelt: 8,
      ),
      // Faixas Verde (Verde Branca, Verde, Verde Preta)
      const Belt(
        id: 'bjj_kids_green_white',
        name: 'Faixa Verde e Branca',
        color: Color(0xFF4CAF50),
        secondaryColor: Colors.white,
        order: 10,
        maxDegrees: 4,
        minClassesForPromotion: 120,
        minMonthsAtBelt: 10,
      ),
      const Belt(
        id: 'bjj_kids_green',
        name: 'Faixa Verde',
        color: Color(0xFF4CAF50),
        order: 11,
        maxDegrees: 4,
        minClassesForPromotion: 130,
        minMonthsAtBelt: 10,
      ),
      const Belt(
        id: 'bjj_kids_green_black',
        name: 'Faixa Verde e Preta',
        color: Color(0xFF4CAF50),
        secondaryColor: Colors.black,
        order: 12,
        maxDegrees: 4,
        minClassesForPromotion: 140,
        minMonthsAtBelt: 10,
      ),
    ],
  );

  // ============================================
  // JUDÔ
  // ============================================
  static final _judo = MartialArt(
    type: MartialArtType.judo,
    name: 'Judô',
    shortName: 'Judô',
    icon: Icons.sports_martial_arts,
    primaryColor: const Color(0xFF0D47A1),
    description: 'Caminho suave - arte marcial japonesa focada em projeções',
    belts: [
      const Belt(
        id: 'judo_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'judo_yellow',
        name: 'Faixa Amarela',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 40,
        minMonthsAtBelt: 3,
      ),
      const Belt(
        id: 'judo_orange',
        name: 'Faixa Laranja',
        color: Color(0xFFFF9800),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 4,
      ),
      const Belt(
        id: 'judo_green',
        name: 'Faixa Verde',
        color: Color(0xFF4CAF50),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 60,
        minMonthsAtBelt: 5,
      ),
      const Belt(
        id: 'judo_blue',
        name: 'Faixa Azul',
        color: Color(0xFF1565C0),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 70,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'judo_brown',
        name: 'Faixa Marrom',
        color: Color(0xFF5D4037),
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 80,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'judo_black',
        name: 'Faixa Preta',
        color: Colors.black,
        order: 6,
        maxDegrees: 10,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 24,
      ),
    ],
  );

  // ============================================
  // KARATÊ
  // ============================================
  static final _karate = MartialArt(
    type: MartialArtType.karate,
    name: 'Karatê',
    shortName: 'Karatê',
    icon: Icons.sports_martial_arts,
    primaryColor: const Color(0xFFD32F2F),
    description: 'Caminho das mãos vazias - arte marcial de Okinawa',
    belts: [
      const Belt(
        id: 'karate_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'karate_yellow',
        name: 'Faixa Amarela',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 30,
        minMonthsAtBelt: 3,
      ),
      const Belt(
        id: 'karate_orange',
        name: 'Faixa Laranja',
        color: Color(0xFFFF9800),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 40,
        minMonthsAtBelt: 4,
      ),
      const Belt(
        id: 'karate_green',
        name: 'Faixa Verde',
        color: Color(0xFF4CAF50),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 5,
      ),
      const Belt(
        id: 'karate_blue',
        name: 'Faixa Azul',
        color: Color(0xFF1565C0),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 60,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'karate_brown',
        name: 'Faixa Marrom',
        color: Color(0xFF5D4037),
        order: 5,
        maxDegrees: 3,
        minClassesForPromotion: 80,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'karate_black',
        name: 'Faixa Preta',
        color: Colors.black,
        order: 6,
        maxDegrees: 10,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 24,
      ),
    ],
  );

  // ============================================
  // MUAY THAI
  // ============================================
  static final _muayThai = MartialArt(
    type: MartialArtType.muayThai,
    name: 'Muay Thai',
    shortName: 'MT',
    icon: Icons.sports_mma,
    primaryColor: const Color(0xFFE65100),
    description: 'Arte das oito armas - boxe tailandês',
    belts: [
      const Belt(
        id: 'mt_white',
        name: 'Prajioud Branco',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'mt_yellow',
        name: 'Prajioud Amarelo',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'mt_green',
        name: 'Prajioud Verde',
        color: Color(0xFF4CAF50),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 70,
        minMonthsAtBelt: 8,
      ),
      const Belt(
        id: 'mt_blue',
        name: 'Prajioud Azul',
        color: Color(0xFF1565C0),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 90,
        minMonthsAtBelt: 10,
      ),
      const Belt(
        id: 'mt_brown',
        name: 'Prajioud Marrom',
        color: Color(0xFF5D4037),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 110,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'mt_red',
        name: 'Prajioud Vermelho',
        color: Color(0xFFC62828),
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 150,
        minMonthsAtBelt: 18,
      ),
      const Belt(
        id: 'mt_black',
        name: 'Prajioud Preto',
        color: Colors.black,
        order: 6,
        maxDegrees: 0,
        minClassesForPromotion: 200,
        minMonthsAtBelt: 24,
      ),
    ],
  );

  // ============================================
  // BOXE
  // ============================================
  static final _boxe = MartialArt(
    type: MartialArtType.boxe,
    name: 'Boxe',
    shortName: 'Boxe',
    icon: Icons.sports_mma,
    primaryColor: const Color(0xFF37474F),
    description: 'Nobre arte - pugilismo',
    belts: [
      const Belt(
        id: 'boxe_iniciante',
        name: 'Iniciante',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'boxe_basico',
        name: 'Básico',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 60,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'boxe_intermediario',
        name: 'Intermediário',
        color: Color(0xFFFF9800),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'boxe_avancado',
        name: 'Avançado',
        color: Color(0xFF4CAF50),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 150,
        minMonthsAtBelt: 18,
      ),
      const Belt(
        id: 'boxe_competidor',
        name: 'Competidor',
        color: Color(0xFF1565C0),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 200,
        minMonthsAtBelt: 24,
      ),
      const Belt(
        id: 'boxe_profissional',
        name: 'Profissional',
        color: Colors.black,
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 300,
        minMonthsAtBelt: 36,
      ),
    ],
  );

  // ============================================
  // TAEKWONDO
  // ============================================
  static final _taekwondo = MartialArt(
    type: MartialArtType.taekwondo,
    name: 'Taekwondo',
    shortName: 'TKD',
    icon: Icons.sports_martial_arts,
    primaryColor: const Color(0xFF1976D2),
    description: 'Caminho dos pés e das mãos - arte marcial coreana',
    belts: [
      const Belt(
        id: 'tkd_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'tkd_yellow',
        name: 'Faixa Amarela',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 30,
        minMonthsAtBelt: 3,
      ),
      const Belt(
        id: 'tkd_green',
        name: 'Faixa Verde',
        color: Color(0xFF4CAF50),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 40,
        minMonthsAtBelt: 4,
      ),
      const Belt(
        id: 'tkd_blue',
        name: 'Faixa Azul',
        color: Color(0xFF1565C0),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 5,
      ),
      const Belt(
        id: 'tkd_red',
        name: 'Faixa Vermelha',
        color: Color(0xFFC62828),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 60,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'tkd_black',
        name: 'Faixa Preta',
        color: Colors.black,
        order: 5,
        maxDegrees: 9,
        minClassesForPromotion: 100,
        minMonthsAtBelt: 12,
      ),
    ],
  );

  // ============================================
  // MMA
  // ============================================
  static final _mma = MartialArt(
    type: MartialArtType.mma,
    name: 'MMA',
    shortName: 'MMA',
    icon: Icons.sports_mma,
    primaryColor: const Color(0xFF424242),
    description: 'Artes Marciais Mistas',
    belts: [
      const Belt(
        id: 'mma_iniciante',
        name: 'Iniciante',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'mma_basico',
        name: 'Básico',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 80,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'mma_intermediario',
        name: 'Intermediário',
        color: Color(0xFFFF9800),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 120,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'mma_avancado',
        name: 'Avançado',
        color: Color(0xFF4CAF50),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 180,
        minMonthsAtBelt: 18,
      ),
      const Belt(
        id: 'mma_competidor',
        name: 'Competidor',
        color: Color(0xFF1565C0),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 250,
        minMonthsAtBelt: 24,
      ),
      const Belt(
        id: 'mma_profissional',
        name: 'Profissional',
        color: Colors.black,
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 400,
        minMonthsAtBelt: 48,
      ),
    ],
  );

  // ============================================
  // KICKBOXING
  // ============================================
  static final _kickboxing = MartialArt(
    type: MartialArtType.kickboxing,
    name: 'Kickboxing',
    shortName: 'KB',
    icon: Icons.sports_mma,
    primaryColor: const Color(0xFFE53935),
    description: 'Combinação de boxe e chutes',
    belts: [
      const Belt(
        id: 'kb_white',
        name: 'Faixa Branca',
        color: Colors.white,
        order: 0,
        maxDegrees: 0,
        minClassesForPromotion: 0,
      ),
      const Belt(
        id: 'kb_yellow',
        name: 'Faixa Amarela',
        color: Color(0xFFFDD835),
        order: 1,
        maxDegrees: 0,
        minClassesForPromotion: 50,
        minMonthsAtBelt: 6,
      ),
      const Belt(
        id: 'kb_orange',
        name: 'Faixa Laranja',
        color: Color(0xFFFF9800),
        order: 2,
        maxDegrees: 0,
        minClassesForPromotion: 70,
        minMonthsAtBelt: 8,
      ),
      const Belt(
        id: 'kb_green',
        name: 'Faixa Verde',
        color: Color(0xFF4CAF50),
        order: 3,
        maxDegrees: 0,
        minClassesForPromotion: 90,
        minMonthsAtBelt: 10,
      ),
      const Belt(
        id: 'kb_blue',
        name: 'Faixa Azul',
        color: Color(0xFF1565C0),
        order: 4,
        maxDegrees: 0,
        minClassesForPromotion: 110,
        minMonthsAtBelt: 12,
      ),
      const Belt(
        id: 'kb_brown',
        name: 'Faixa Marrom',
        color: Color(0xFF5D4037),
        order: 5,
        maxDegrees: 0,
        minClassesForPromotion: 140,
        minMonthsAtBelt: 18,
      ),
      const Belt(
        id: 'kb_black',
        name: 'Faixa Preta',
        color: Colors.black,
        order: 6,
        maxDegrees: 5,
        minClassesForPromotion: 200,
        minMonthsAtBelt: 24,
      ),
    ],
  );
}

