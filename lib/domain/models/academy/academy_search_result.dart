import 'package:equatable/equatable.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Resultado de busca de academia (versão simplificada)
class AcademySearchResult extends Equatable {
  const AcademySearchResult({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.city,
    this.state,
    this.modalities = const [],
    this.studentCount,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? city;
  final String? state;
  final List<MartialArtType> modalities;
  final int? studentCount;

  /// Retorna localização formatada
  String get location {
    if (city != null && state != null) {
      return '$city, $state';
    }
    return city ?? state ?? '';
  }

  /// Retorna nomes das modalidades
  String get modalitiesText {
    if (modalities.isEmpty) return '';
    return modalities
        .map((t) => MartialArtsConfig.getByType(t).shortName)
        .join(' • ');
  }

  @override
  List<Object?> get props => [
        id,
        name,
        logoUrl,
        description,
        city,
        state,
        modalities,
        studentCount,
      ];
}

/// Status da solicitação de vínculo
enum MemberRequestStatus {
  none,      // Não tem solicitação
  pending,   // Aguardando aprovação
  approved,  // Aprovado (já é membro)
  rejected,  // Rejeitado
}

