import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_search_result.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Implementação do AcademySearchRepository usando Supabase
class AcademySearchRepositorySupabase implements AcademySearchRepository {
  AcademySearchRepositorySupabase({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<List<AcademySearchResult>>> searchAcademies({
    String? query,
    String? city,
    MartialArtType? modalityType,
  }) async {
    try {
      final data = await _supabaseService.searchAcademies(
        query: query,
        city: city,
        modalityType: modalityType?.name,
      );

      final results = data.map((academy) {
        // Parse modalidades
        final modalitiesData =
            academy['academy_modalities'] as List<dynamic>? ?? [];
        final modalities = modalitiesData.map((m) {
          final typeStr = m['martial_art_type'] as String;
          return MartialArtType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => MartialArtType.jiuJitsu,
          );
        }).toList();

        return AcademySearchResult(
          id: academy['id'] as String,
          name: academy['name'] as String,
          logoUrl: academy['logo_url'] as String?,
          description: academy['description'] as String?,
          city: academy['city'] as String?,
          state: academy['state'] as String?,
          modalities: modalities,
        );
      }).toList();

      return Result.success(results);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar academias: $e'));
    }
  }

  @override
  Future<Result<MemberRequestStatus>> getRequestStatus({
    required String academyId,
    required String oderId,
  }) async {
    try {
      // Primeiro busca o user_id pelo firebase_uid
      final user = await _supabaseService.getUserByFirebaseUid(oderId);
      if (user == null) {
        return Result.success(MemberRequestStatus.none);
      }

      final userId = user['id'] as String;
      final request =
          await _supabaseService.getPendingRequest(academyId, userId);

      if (request == null) {
        return Result.success(MemberRequestStatus.none);
      }

      final status = request['status'] as String?;
      switch (status) {
        case 'pending':
          return Result.success(MemberRequestStatus.pending);
        case 'approved':
          return Result.success(MemberRequestStatus.approved);
        case 'rejected':
          return Result.success(MemberRequestStatus.rejected);
        default:
          return Result.success(MemberRequestStatus.none);
      }
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao verificar status: $e'));
    }
  }

  @override
  Future<Result<void>> sendJoinRequest({
    required String academyId,
    required String oderId,
    List<MartialArtType>? modalities,
    String? message,
  }) async {
    try {
      // Primeiro busca o user_id pelo firebase_uid
      var user = await _supabaseService.getUserByFirebaseUid(oderId);
      
      // Se o usuário não existe na tabela users, cria um registro básico
      user ??= await _supabaseService.upsertUser({
          'firebase_uid': oderId,
          'email': '', // Será preenchido depois se necessário
          'role': 'student',
        });

      final userId = user['id'] as String;

      // Verifica se já existe solicitação
      final existing =
          await _supabaseService.getPendingRequest(academyId, userId);
      if (existing != null) {
        final status = existing['status'] as String?;
        if (status == 'approved') {
          return Result.failure(
              Failure(message: 'Você já é membro desta academia'));
        }
        if (status == 'pending') {
          return Result.failure(
              Failure(message: 'Você já tem uma solicitação pendente'));
        }
      }

      // Cria a solicitação com campos básicos
      final requestData = <String, dynamic>{
        'academy_id': academyId,
        'user_id': userId,
        'status': 'pending',
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _supabaseService.createMemberRequest(requestData);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao enviar solicitação: $e'));
    }
  }

  @override
  Future<Result<void>> cancelJoinRequest({
    required String academyId,
    required String oderId,
  }) async {
    try {
      // Primeiro busca o user_id pelo firebase_uid
      final user = await _supabaseService.getUserByFirebaseUid(oderId);
      if (user == null) {
        return Result.failure(Failure(message: 'Usuário não encontrado'));
      }

      final userId = user['id'] as String;

      // Busca a solicitação
      final request =
          await _supabaseService.getPendingRequest(academyId, userId);
      if (request == null) {
        return Result.failure(Failure(message: 'Solicitação não encontrada'));
      }

      // Cancela
      await _supabaseService.cancelMemberRequest(request['id'] as String);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao cancelar solicitação: $e'));
    }
  }

  @override
  Future<Result<List<JoinRequest>>> getPendingRequests(String academyId) async {
    try {
      final data = await _supabaseService.getPendingRequests(academyId);

      final requests = <JoinRequest>[];
      
      for (final request in data) {
        final userData = request['users'] as Map<String, dynamic>?;

        // Parse modalidades solicitadas (campo opcional)
        final modalitiesData =
            request['requested_modalities'] as List<dynamic>? ?? [];
        final modalities = modalitiesData.map((m) {
          return MartialArtType.values.firstWhere(
            (t) => t.name == m,
            orElse: () => MartialArtType.jiuJitsu,
          );
        }).toList();

        requests.add(JoinRequest(
          memberId: request['id'] as String,
          oderId: request['user_id'] as String? ?? '',
          email: userData?['email'] as String? ?? '',
          displayName: userData?['display_name'] as String?,
          photoUrl: userData?['photo_url'] as String?,
          requestedAt: request['created_at'] != null
              ? DateTime.tryParse(request['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
          message: request['request_message'] as String?,
          requestedModalities: modalities,
        ));
      }

      return Result.success(requests);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao buscar solicitações: $e'));
    }
  }

  @override
  Future<Result<void>> approveRequest(String memberId) async {
    try {
      await _supabaseService.approveMemberRequest(memberId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao aprovar solicitação: $e'));
    }
  }

  @override
  Future<Result<void>> rejectRequest(String memberId) async {
    try {
      await _supabaseService.rejectMemberRequest(memberId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao rejeitar solicitação: $e'));
    }
  }
}

