import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_search_result.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Migracao gradual: usa Backend API para busca de academias com fallback.
class AcademySearchRepositoryHybrid implements AcademySearchRepository {
  AcademySearchRepositoryHybrid({
    required BackendApiClient backendApiClient,
  })  : _backendApiClient = backendApiClient;

  final BackendApiClient _backendApiClient;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<List<AcademySearchResult>>> searchAcademies({
    String? query,
    String? city,
    MartialArtType? modalityType,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/search',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (modalityType != null) 'modality': modalityType.name,
        },
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(Failure(message: 'Erro ao buscar academias', code: 'academies_not_found'));
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapAcademySearchResult)
          .toList();

      return Result.success(items);
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao buscar academias', code: 'academies_not_found'));
    }
  }

  @override
  Future<Result<MemberRequestStatus>> getRequestStatus({
    required String academyId,
    required String oderId,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/membership/me',
      );
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(Failure(message: 'Erro ao buscar status de requisição', code: 'request_status_not_found'));
      }

      final map = response.data as Map<String, dynamic>;
      final status = (map['status'] as String? ?? '').toLowerCase();
      switch (status) {
        case 'pending':
          return Result.success(MemberRequestStatus.pending);
        case 'approved':
          return Result.success(MemberRequestStatus.approved);
        case 'cancelled':
        case 'suspended':
        case 'rejected':
          return Result.success(MemberRequestStatus.rejected);
        case 'none':
        default:
          return Result.success(MemberRequestStatus.none);
      }
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao buscar status de requisição', code: 'request_status_not_found'));
    }
  }

  @override
  Future<Result<void>> sendJoinRequest({
    required String academyId,
    required String oderId,
    List<MartialArtType>? modalities,
    String? message,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
    }

    try {
      final response = await _backendApiClient.post(
        '/v1/academies/$academyId/membership-requests',
        body: {
          'academy_id': academyId,
          'oder_id': oderId,
          'modalities': modalities?.map((m) => m.name).join(','),
          'message': message,
        },
      );
      if (response.isSuccess) {
        return Result.success(null);
      }
          return Result.failure(Failure(message: 'Erro ao enviar requisição de adesão', code: 'join_request_failed'));
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao enviar requisição de adesão', code: 'join_request_failed'));
    }
  }

  @override
  Future<Result<void>> cancelJoinRequest({
    required String academyId,
    required String oderId,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
       
    }

    try {
      final response = await _backendApiClient.delete(
        '/v1/academies/$academyId/membership-requests/me',
      );
      if (response.isSuccess || response.statusCode == 404) {
        return Result.success(null);
      }

          return Result.failure(Failure(message: 'Erro ao cancelar requisição de adesão', code: 'join_request_cancel_failed'));
    } catch (_) {
      return Result.failure(Failure(message: 'Erro ao cancelar requisição de adesão', code: 'join_request_cancel_failed'));
    }
  }

  @override
  Future<Result<List<JoinRequest>>> getPendingRequests(String academyId) async {
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
  }

  @override
  Future<Result<void>> approveRequest(String memberId) async {
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
  }

  @override
  Future<Result<void>> rejectRequest(String memberId) async   { 
    return Result.failure(Failure(message: 'Backend API não disponível', code: 'backend_api_not_available'));
  }

  AcademySearchResult _mapAcademySearchResult(Map<String, dynamic> academy) {
    final modalitiesData = academy['academy_modalities'] as List<dynamic>? ?? [];
    final modalities = modalitiesData
        .whereType<Map<String, dynamic>>()
        .map((m) => m['martial_art_type'] as String?)
        .whereType<String>()
        .map((typeStr) => MartialArtType.values.firstWhere(
              (t) => t.name == typeStr,
              orElse: () => MartialArtType.jiuJitsu,
            ))
        .toList();

    return AcademySearchResult(
      id: academy['id'] as String? ?? '',
      name: academy['name'] as String? ?? '',
      logoUrl: academy['logo_url'] as String?,
      description: academy['description'] as String?,
      city: academy['city'] as String?,
      state: academy['state'] as String?,
      modalities: modalities,
    );
  }
}

