import 'dart:io';

import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository_supabase.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

class ProfileRepositoryHybrid implements ProfileRepository {
  ProfileRepositoryHybrid({
    required BackendApiClient backendApiClient,
    required ProfileRepositorySupabase supabaseRepository,
  })  : _backendApiClient = backendApiClient,
        _supabaseRepository = supabaseRepository;

  final BackendApiClient _backendApiClient;
  final ProfileRepositorySupabase _supabaseRepository;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    if (!_canUseBackend) {
      return _supabaseRepository.getProfile(userId);
    }

    try {
      final response = await _backendApiClient.get('/v1/me');
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return _supabaseRepository.getProfile(userId);
      }

      final map = response.data as Map<String, dynamic>;
      final profile = _mapBackendMeToProfile(map);
      await _supabaseRepository.saveProfile(profile);
      return Result.success(profile);
    } catch (_) {
      return _supabaseRepository.getProfile(userId);
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) async* {
    final result = await getProfile(userId);
    yield result.fold(
      onSuccess: (profile) => profile,
      onFailure: (_) => null,
    );
  }

  @override
  Future<Result<void>> saveProfile(UserProfile profile) async {
    if (!_canUseBackend) {
      return _supabaseRepository.saveProfile(profile);
    }
    final backendResult = await _updateBackendProfile(profile);
    if (!backendResult.isSuccess) {
      return backendResult;
    }
    await _supabaseRepository.saveProfile(profile);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    if (!_canUseBackend) {
      return _supabaseRepository.updateProfile(profile);
    }
    final backendResult = await _updateBackendProfile(profile);
    if (!backendResult.isSuccess) {
      return backendResult;
    }
    await _supabaseRepository.updateProfile(profile);
    return Result.success(null);
  }

  @override
  Future<Result<String>> uploadProfileImage(String userId, File image) {
    // Upload de avatar no backend exige multipart/form-data.
    // Mantemos o upload no Supabase enquanto o client multipart não é migrado.
    return _supabaseRepository.uploadProfileImage(userId, image);
  }

  Future<Result<void>> _updateBackendProfile(UserProfile profile) async {
    final payload = <String, dynamic>{
      if (profile.displayName != null && profile.displayName!.trim().isNotEmpty)
        'display_name': profile.displayName!.trim(),
      'role': profile.role.name,
      if (profile.martialArtType != null)
        'martial_art_type': profile.martialArtType!.name,
      if (profile.graduation?.beltId != null)
        'legacy_belt_id': profile.graduation!.beltId,
      if (profile.graduation?.degree != null)
        'legacy_degree': profile.graduation!.degree,
      'legacy_total_classes': profile.totalClasses,
      if (profile.graduation?.hasAparadores != null)
        'legacy_has_aparadores': profile.graduation!.hasAparadores,
    };

    final response = await _backendApiClient.put('/v1/me', body: payload);
    if (!response.isSuccess) {
      final message = _extractMessage(response) ?? 'Erro ao atualizar perfil';
      return Result.failure(
        Failure(message: message, code: 'backend_profile_update_failed'),
      );
    }
    return Result.success(null);
  }

  UserProfile _mapBackendMeToProfile(Map<String, dynamic> map) {
    final roleName = map['role'] as String? ?? UserRole.student.name;
    final role = UserRole.values.firstWhere(
      (value) => value.name == roleName,
      orElse: () => UserRole.student,
    );

    final martialArtRaw = map['martial_art_type'] as String?;
    final martialArtType = martialArtRaw == null
        ? null
        : MartialArtType.values.firstWhere(
            (value) => value.name == martialArtRaw,
            orElse: () => MartialArtType.jiuJitsu,
          );

    final legacyBeltId = map['legacy_belt_id'] as String?;
    final legacyDegree = map['legacy_degree'] as int?;
    final hasAparadores = map['legacy_has_aparadores'] as bool?;
    final graduation = legacyBeltId == null
        ? null
        : UserGraduation(
            beltId: legacyBeltId,
            degree: legacyDegree ?? 0,
            classesAtCurrentBelt: 0,
            hasAparadores: hasAparadores,
          );

    return UserProfile(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      role: role,
      martialArtType: martialArtType,
      graduation: graduation,
      totalClasses: map['legacy_total_classes'] as int? ?? 0,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String? _extractMessage(BackendApiResponse response) {
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final error = map['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (response.rawBody != null && response.rawBody!.trim().isNotEmpty) {
      return response.rawBody;
    }
    return null;
  }
}

