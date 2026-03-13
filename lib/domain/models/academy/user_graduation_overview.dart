import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/academy/student_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Visão agregada das informações de graduação do usuário.
///
/// - Usa `StudentModality` como fonte principal (por modalidade).
/// - Faz fallback para campos legados (martialArtType/graduation/etc.)
///   quando o usuário não está vinculado a uma academia.
class UserGraduationOverview extends Equatable {
  const UserGraduationOverview({
    required this.modalities,
    this.legacyMartialArtType,
    this.legacyGraduation,
    this.legacyGraduationHistory = const [],
    this.legacyTotalClasses = 0,
    this.legacyStartDate,
  });

  /// Modalidades em que o aluno está matriculado (fonte principal de graduação).
  final List<StudentModality> modalities;

  /// Campos legados para usuários sem academia.
  final MartialArtType? legacyMartialArtType;
  final UserGraduation? legacyGraduation;
  final List<GraduationHistory> legacyGraduationHistory;
  final int legacyTotalClasses;
  final DateTime? legacyStartDate;

  /// Modalidade principal (hoje usamos a primeira como referência).
  StudentModality? get primaryModality =>
      modalities.isNotEmpty ? modalities.first : null;

  /// Arte marcial principal (modalidade ou legado).
  MartialArt get martialArt {
    if (primaryModality != null) {
      return primaryModality!.martialArt;
    }
    if (legacyMartialArtType != null) {
      return MartialArtsConfig.getByType(legacyMartialArtType!);
    }
    return MartialArtsConfig.defaultArt;
  }

  /// Faixa atual do usuário.
  Belt? get currentBelt {
    if (primaryModality != null) {
      return primaryModality!.currentBelt;
    }
    if (legacyGraduation == null) {
      return martialArt.initialBelt;
    }
    return martialArt.getBeltById(legacyGraduation!.beltId);
  }

  /// Próxima faixa.
  Belt? get nextBelt {
    if (primaryModality != null) {
      return primaryModality!.nextBelt;
    }
    final current = currentBelt;
    if (current == null) return null;
    return martialArt.getNextBelt(current);
  }


  /// Aulas restantes até o próximo grau na modalidade principal.
  int get classesUntilNextDegree {
    if (primaryModality != null) {
      return primaryModality!.classesUntilNextDegree;
    }
    // Perfis legados não têm configuração de graus por academia.
    return 0;
  }

  /// Total de aulas em todas as modalidades (ou legado).
  int get totalClassesAll {
    if (modalities.isNotEmpty) {
      return modalities.fold(0, (sum, m) => sum + m.totalClasses);
    }
    return legacyTotalClasses;
  }

  /// Tempo total de treino (baseado em `legacyStartDate`).
  Duration? get trainingTime {
    if (legacyStartDate == null) return null;
    return DateTime.now().difference(legacyStartDate!);
  }

  /// Recupera uma modalidade específica.
  StudentModality? getModality(MartialArtType type) {
    try {
      return modalities.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Verifica se está matriculado em uma modalidade específica.
  bool isEnrolledIn(MartialArtType type) =>
      modalities.any((m) => m.type == type);

  @override
  List<Object?> get props => [
        modalities,
        legacyMartialArtType,
        legacyGraduation,
        legacyGraduationHistory,
        legacyTotalClasses,
        legacyStartDate,
      ];
}

