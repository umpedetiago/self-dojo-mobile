import 'dart:io';

import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/dtos/backend/me_response_dto.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
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
    final dto = BackendMeResponseDto.fromJson(map);

    Map<String, AcademyModality>? academyModalitiesById;
    if (dto.academyId != null && dto.academyId!.isNotEmpty) {
      academyModalitiesById =
          await _loadAcademyModalities(dto.academyId!);
    }

    final profile =
        _mapBackendProfile(dto, academyModalitiesById: academyModalitiesById);
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

  Future<Map<String, AcademyModality>> _loadAcademyModalities(
    String academyId,
  ) async {
    try {
      final response = await _backendApiClient.get('/v1/academies/$academyId');
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return {};
      }

      final map = response.data as Map<String, dynamic>;
      final rawModalities =
          (map['academy_modalities'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

      final items = rawModalities
          .map(_mapAcademyModalityFromBackend)
          .toList();

      return {
        for (final modality in items) modality.id: modality,
      };
    } catch (_) {
      return {};
    }
  }

  AcademyModality _mapAcademyModalityFromBackend(
    Map<String, dynamic> data,
  ) {
    final typeStr = data['martial_art_type'] as String? ?? 'jiuJitsu';
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    final beltConfigsData =
        (data['belt_configs'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

    final beltConfigs = beltConfigsData.map((b) {
      return BeltConfig(
        beltId: b['belt_id'] as String? ?? '',
        minClasses: b['min_classes'] as int? ?? 0,
        minMonths: b['min_months'] as int?,
        minClassesPerDegree:
            b['min_classes_per_degree'] as int?,
        requiresExam: b['requires_exam'] as bool? ?? false,
        examFee: (b['exam_fee'] as num?)?.toDouble(),
        notes: b['notes'] as String?,
      );
    }).toList();

    final graduationConfig = GraduationConfig(
      martialArtType: type,
      belts: beltConfigs,
      useDefaultConfig:
          data['use_default_graduation'] as bool? ?? true,
      configuredBy: null,
      lastUpdated: data['graduation_updated_at'] != null
          ? DateTime.tryParse(
              data['graduation_updated_at'].toString(),
            )
          : null,
    );

    final teacherIds =
        (data['teacher_ids'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    return AcademyModality(
      id: data['id'] as String? ?? '',
      type: type,
      masterId: data['master_id'] as String?,
      teacherIds: teacherIds,
      instructorIds: const [],
      graduationConfig: graduationConfig,
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  UserProfile _mapBackendProfile(
    BackendMeResponseDto dto, {
    Map<String, AcademyModality>? academyModalitiesById,
  }) {
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
        type = MartialArtType.values
            .firstWhere((t) => t.name == m.martialArtType);
      } catch (_) {
        type = MartialArtType.jiuJitsu;
      }

      final art = MartialArtsConfig.getByType(type);
      final beltId =
          m.beltId.isNotEmpty ? m.beltId : art.initialBelt?.id;

      AcademyModality? academyModality;
      if (academyModalitiesById != null &&
          academyModalitiesById.isNotEmpty) {
        academyModality = academyModalitiesById[m.modalityId];
        if (academyModality == null) {
          try {
            academyModality = academyModalitiesById.values
                .firstWhere((mod) => mod.type == type);
          } catch (_) {
            academyModality = null;
          }
        }
      }

      return StudentModality(
        type: type,
        assignedTeacherId: m.assignedTeacherId,
        graduation: UserGraduation(
          beltId: beltId ?? '',
          degree: m.degree,
          promotionDate: m.promotionDate,
          classesAtCurrentBelt: m.classesAtCurrentBelt,
          hasAparadores: dto.hasAparadores,
        ),
        graduationHistory: m.graduationHistory
            .where((h) => h.beltId.isNotEmpty)
            .map(
              (h) => GraduationHistory(
                beltId: h.beltId,
                degree: h.degree,
                date: h.promotedAt ?? DateTime.now(),
                notes: h.notes,
              ),
            )
            .toList(),
        totalClasses: m.totalClasses,
        enrolledAt: m.enrolledAt ?? DateTime.now(),
        backendClassesUntilNextBelt: m.classesUntilNextBelt,
        backendClassesUntilNextDegree: m.classesUntilNextDegree,
        backendTrainingTimeDays: m.trainingTimeDays,
        academyModality: academyModality,
      );
    }).toList();

    StudentModality? primaryModality;
    if (dto.primaryStudentModalityId != null &&
        dto.primaryStudentModalityId!.isNotEmpty) {
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
    primaryModality ??= enrolledModalities.isNotEmpty
        ? enrolledModalities.first
        : null;

    final totalClasses =
        dto.totalClassesAll ?? primaryModality?.totalClasses ?? 0;

    // Deriva uma data de início aproximada a partir do total de dias de treino,
    // se o backend fornecer esse dado agregado.
    DateTime? derivedStartDate;
    if (dto.trainingTimeDays != null && dto.trainingTimeDays! > 0) {
      derivedStartDate =
          DateTime.now().subtract(Duration(days: dto.trainingTimeDays!));
    }

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
      graduationHistory:
          primaryModality?.graduationHistory ?? const [],
      totalClasses: totalClasses,
      academyName: dto.academyName,
      instructorName: dto.instructorName,
      weightCategory: dto.weightCategory,
      startDate: derivedStartDate,
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
