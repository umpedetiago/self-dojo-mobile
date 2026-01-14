import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_search_result.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Repository para busca de academias e solicitações de vínculo
abstract class AcademySearchRepository {
  /// Busca academias por texto
  Future<Result<List<AcademySearchResult>>> searchAcademies({
    String? query,
    String? city,
    MartialArtType? modalityType,
  });

  /// Verifica status de solicitação do usuário para uma academia
  Future<Result<MemberRequestStatus>> getRequestStatus({
    required String academyId,
    required String oderId,
  });

  /// Envia solicitação de vínculo
  Future<Result<void>> sendJoinRequest({
    required String academyId,
    required String oderId,
    List<MartialArtType>? modalities,
    String? message,
  });

  /// Cancela solicitação pendente
  Future<Result<void>> cancelJoinRequest({
    required String academyId,
    required String oderId,
  });

  /// Busca solicitações pendentes (para owner/professor)
  Future<Result<List<JoinRequest>>> getPendingRequests(String academyId);

  /// Aprova solicitação
  Future<Result<void>> approveRequest(String memberId);

  /// Rejeita solicitação
  Future<Result<void>> rejectRequest(String memberId);
}

/// Modelo de solicitação de vínculo
class JoinRequest {
  const JoinRequest({
    required this.memberId,
    required this.oderId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.requestedAt,
    this.message,
    this.requestedModalities = const [],
  });

  final String memberId;
  final String oderId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime requestedAt;
  final String? message;
  final List<MartialArtType> requestedModalities;

  String get name => displayName ?? email.split('@').first;
}

