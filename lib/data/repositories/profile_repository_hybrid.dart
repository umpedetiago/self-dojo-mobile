import 'dart:io';

import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/dtos/backend/me_response_dto.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/student_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

class ProfileRepositoryHybrid implements ProfileRepository {
  ProfileRepositoryHybrid({
    required BackendApiClient backendApiClient,
  }) : _backendApiClient = backendApiClient;

  final BackendApiClient _backendApiClient;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    if (!_canUseBackend) {
      return Result.failure(
        Failure(
          message: 'Backend API não disponível',
          code: 'backend_api_not_available',
        ),
      );
    }

    final response = await _backendApiClient.get('/v1/me');

    if (!response.isSuccess || response.data is! Map<String, dynamic>) {
      return Result.failure(
        Failure(
          message: 'Erro ao buscar perfil',
          code: 'profile_not_found',
        ),
      );
    }

    final map = response.data as Map<String, dynamic>;
    final profile = _mapBackendProfile(map);
    return Result.success(profile);
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
      return Result.failure(
        Failure(
          message: 'Backend API não disponível',
          code: 'backend_api_not_available',
        ),
      );
    }

    final payload = _buildUpdatePayload(profile);
    final response = await _backendApiClient.put('/v1/me', body: payload);
    if (!response.isSuccess) {
      return Result.failure(
        Failure(
          message: 'Erro ao salvar perfil',
          code: 'profile_save_failed',
        ),
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    if (!_canUseBackend) {
      return Result.failure(
        Failure(
          message: 'Backend API não disponível',
          code: 'backend_api_not_available',
        ),
      );
    }

    final payload = _buildUpdatePayload(profile);
    final response = await _backendApiClient.put('/v1/me', body: payload);
    if (!response.isSuccess) {
      return Result.failure(
        Failure(
          message: 'Erro ao atualizar perfil',
          code: 'profile_update_failed',
        ),
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<String>> uploadProfileImage(String userId, File image) async {
    return Result.failure(
      const Failure(
        message:
            'Upload de imagem de perfil via mobile ainda não está implementado na Backend API.',
        code: 'profile_image_upload_not_implemented',
      ),
    );
  }

  UserProfile _mapBackendProfile(Map<String, dynamic> data) {
    final dto = BackendMeResponseDto.fromJson(data);

    final role = UserRole.values.firstWhere(
      (r) => r.name == dto.role,
      orElse: () => UserRole.student,
    );

    MartialArtType? martialArtType;
    if (dto.martialArtType != null && dto.martialArtType!.isNotEmpty) {
      try {
        martialArtType = MartialArtType.values.firstWhere(
          (t) => t.name == dto.martialArtType,
        );
      } catch (_) {
        martialArtType = null;
      }
    }

    final enrolledModalities = dto.studentModalities.map((m) {
      MartialArtType type = MartialArtType.jiuJitsu;
      try {
        type = MartialArtType.values.firstWhere((t) => t.name == m.martialArtType);
      } catch (_) {
        type = MartialArtType.jiuJitsu;
      }

      final art = MartialArtsConfig.getByType(type);
      final beltId = m.beltId.isNotEmpty ? m.beltId : art.initialBelt.id;

      return StudentModality(
        type: type,
        assignedTeacherId: m.assignedTeacherId,
        graduation: UserGraduation(
          beltId: beltId,
          degree: m.degree,
          promotionDate: m.promotionDate,
          classesAtCurrentBelt: m.classesAtCurrentBelt,
          hasAparadores: dto.hasAparadores,
        ),
        graduationHistory: m.graduationHistory
            .where((h) => h.beltId.isNotEmpty)
            .map((h) => GraduationHistory(
                  beltId: h.beltId,
                  degree: h.degree,
                  date: h.promotedAt ?? DateTime.now(),
                  notes: h.notes,
                ))
            .toList(),
        totalClasses: m.totalClasses,
        enrolledAt: m.enrolledAt ?? DateTime.now(),
      );
    }).toList();

    StudentModality? primaryModality;
    if (dto.primaryStudentModalityId != null && dto.primaryStudentModalityId!.isNotEmpty) {
      for (var i = 0; i < enrolledModalities.length; i++) {
        final m = dto.studentModalities[i];
        if (m.id == dto.primaryStudentModalityId) {
          primaryModality = enrolledModalities[i];
          break;
        }
      }
    }
    if (primaryModality == null &&
        martialArtType != null &&
        enrolledModalities.isNotEmpty) {
      final targetType = martialArtType;
      primaryModality = enrolledModalities.firstWhere(
        (m) => m.type == targetType,
        orElse: () => enrolledModalities.first,
      );
    }
    primaryModality ??= enrolledModalities.isNotEmpty ? enrolledModalities.first : null;

    final totalClasses = primaryModality?.totalClasses ?? 0;

    return UserProfile(
      id: dto.id,
      email: dto.email,
      displayName: dto.displayName,
      photoUrl: dto.photoUrl,
      role: role,
      // Academia (opcional na resposta)
      academyId: dto.academyId,
      academyStatus: dto.academyStatus != null
          ? AcademyStatus.values.firstWhere(
              (s) => s.name == dto.academyStatus,
              orElse: () => AcademyStatus.pending,
            )
          : null,
      joinedAcademyAt: dto.joinedAt,
      // Modalidades/graduação (fonte principal)
      enrolledModalities: enrolledModalities,
      // Campos de conveniência (mantém compat com UI/legado)
      martialArtType: primaryModality?.type ?? martialArtType,
      graduation: primaryModality?.graduation,
      graduationHistory: primaryModality?.graduationHistory ?? const [],
      totalClasses: totalClasses,
      createdAt: dto.createdAt,
    );
  }

  Map<String, dynamic> _buildUpdatePayload(UserProfile profile) {
    return <String, dynamic>{
      if (profile.displayName != null)
        'display_name': profile.displayName,
      'role': profile.role.name,
      if (profile.martialArtType != null)
        'martial_art_type': profile.martialArtType!.name,
      // TODO: permitir atualização de outros campos de perfil
      // (como username) quando fizer sentido para o app mobile.
    };
  }
}
