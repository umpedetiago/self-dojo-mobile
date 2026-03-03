import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Implementação de [AcademyRepository] usando apenas a Backend API.
class AcademyRepositoryHybrid implements AcademyRepository {
  AcademyRepositoryHybrid({
    required BackendApiClient backendApiClient,
  }) : _backendApiClient = backendApiClient;

  final BackendApiClient _backendApiClient;

  bool get _canUseBackend => _backendApiClient.canCallProtectedApi;

  @override
  Future<Result<Academy?>> getAcademy(String academyId) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final response = await _backendApiClient.get('/v1/academies/$academyId');
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao buscar academia (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final academy = _mapAcademy(response.data as Map<String, dynamic>);
      return Result.success(academy);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar academia: $e'),
      );
    }
  }

  @override
  Stream<Academy?> watchAcademy(String academyId) async* {
    final result = await getAcademy(academyId);
    yield result.fold(
      onSuccess: (academy) => academy,
      onFailure: (_) => null,
    );
  }

  @override
  Future<Result<Academy>> createAcademy({
    required String ownerId,
    required String name,
    required List<MartialArtType> modalities,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? email,
  }) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final payload = {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'modalities': modalities.map((m) => m.name).toList(),
      };

      final response = await _backendApiClient.post(
        '/v1/academies',
        body: payload,
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao criar academia (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final academy = _mapAcademy(response.data as Map<String, dynamic>);
      return Result.success(academy);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar academia: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateAcademy(Academy academy) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final payload = {
        'name': academy.name,
        'description': academy.description,
        'logo_url': academy.logoUrl,
        'address': academy.address,
        'city': academy.city,
        'state': academy.state,
        'phone': academy.phone,
        'email': academy.email,
        'website': academy.website,
        'is_active': academy.isActive,
      };

      final response = await _backendApiClient.patch(
        '/v1/academies/${academy.id}',
        body: payload,
      );

      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao atualizar academia (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar academia: $e'),
      );
    }
  }

  @override
  Future<Result<Academy?>> getOwnerAcademy(String ownerId) async {
    final result = await getOwnerAcademies(ownerId);
    return result.fold(
      onSuccess: (items) =>
          items.isNotEmpty ? Result.success(items.first) : Result.success(null),
      onFailure: Result.failure,
    );
  }

  @override
  Future<Result<List<Academy>>> getOwnerAcademies(String ownerId) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies',
        queryParameters: {'owner': 'me'},
      );

      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao listar academias (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final map = response.data as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapAcademy)
          .toList();

      return Result.success(items);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao listar academias: $e'),
      );
    }
  }

  @override
  Future<Result<void>> addModality(
    String academyId,
    MartialArtType type,
  ) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final response = await _backendApiClient.post(
        '/v1/academies/$academyId/modalities',
        body: {
          'martial_art_type': type.name,
        },
      );

      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao criar modalidade (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar modalidade: $e'),
      );
    }
  }

  @override
  Future<Result<void>> removeModality(
    String academyId,
    MartialArtType type,
  ) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final academyResult = await getAcademy(academyId);
      final academy = academyResult.fold(
        onSuccess: (a) => a,
        onFailure: (_) => null,
      );
      if (academy == null) {
        return Result.failure(
          const Failure(message: 'Academia não encontrada'),
        );
      }

      final modality =
          academy.modalities.firstWhere((m) => m.type == type, orElse: () => throw Exception());

      final response = await _backendApiClient.delete(
        '/v1/academies/$academyId/modalities/${modality.id}',
      );

      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao remover modalidade (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao remover modalidade: $e'),
      );
    }
  }

  @override
  Future<Result<void>> setModalityMaster(
    String academyId,
    MartialArtType type,
    String? masterId,
  ) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final academyResult = await getAcademy(academyId);
      final academy = academyResult.fold(
        onSuccess: (a) => a,
        onFailure: (_) => null,
      );
      if (academy == null) {
        return Result.failure(
          const Failure(message: 'Academia não encontrada'),
        );
      }

      final modality =
          academy.modalities.firstWhere((m) => m.type == type, orElse: () => throw Exception());

      final response = await _backendApiClient.put(
        '/v1/academies/$academyId/modalities/${modality.id}/master',
        body: {'master_id': masterId},
      );

      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao definir mestre (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao definir mestre: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateGraduationConfig(
    String academyId,
    MartialArtType type,
    GraduationConfig config,
  ) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final academyResult = await getAcademy(academyId);
      final academy = academyResult.fold(
        onSuccess: (a) => a,
        onFailure: (_) => null,
      );
      if (academy == null) {
        return Result.failure(
          const Failure(message: 'Academia não encontrada'),
        );
      }

      final modality =
          academy.modalities.firstWhere((m) => m.type == type, orElse: () => throw Exception());

      final beltConfigs = config.belts
          .map((b) => {
                'belt_id': b.beltId,
                'belt_name': MartialArtsConfig.getByType(type)
                    .getBeltById(b.beltId)
                    ?.name,
                'min_classes': b.minClasses,
                'min_months': b.minMonths,
                'min_classes_per_degree': b.minClassesPerDegree,
                'requires_exam': b.requiresExam,
                'exam_fee': b.examFee,
                'notes': b.notes,
              })
          .toList();

      final response = await _backendApiClient.put(
        '/v1/academies/$academyId/modalities/${modality.id}/graduation-config',
        body: {
          'use_default_graduation': config.useDefaultConfig,
          'belt_configs': beltConfigs,
        },
      );

      if (!response.isSuccess) {
        return Result.failure(
          Failure(
            message:
                'Erro ao atualizar graduação (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar graduação: $e'),
      );
    }
  }

  @override
  Future<Result<int>> countStudents(String academyId) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/stats',
      );
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao buscar estatísticas (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final map = response.data as Map<String, dynamic>;
      final approved = map['approved_members'] as int? ?? 0;
      return Result.success(approved);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar estatísticas: $e'),
      );
    }
  }

  @override
  Future<Result<int>> countPendingRequests(String academyId) async {
    if (!_canUseBackend) {
      return Result.failure(
        const Failure(message: 'Backend API não configurada para academias'),
      );
    }

    try {
      final response = await _backendApiClient.get(
        '/v1/academies/$academyId/stats',
      );
      if (!response.isSuccess || response.data is! Map<String, dynamic>) {
        return Result.failure(
          Failure(
            message:
                'Erro ao buscar estatísticas (${response.statusCode}): ${response.rawBody ?? ''}',
          ),
        );
      }

      final map = response.data as Map<String, dynamic>;
      final pending = map['pending_requests'] as int? ?? 0;
      return Result.success(pending);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar estatísticas: $e'),
      );
    }
  }

  Academy _mapAcademy(Map<String, dynamic> map) {
    final modalitiesData =
        (map['academy_modalities'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();

    final modalities = modalitiesData.map(_mapAcademyModality).toList();

    return Academy(
      id: map['id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      logoUrl: map['logo_url'] as String?,
      description: map['description'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      modalities: modalities,
      financialConfig: null,
      subscription: null,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  AcademyModality _mapAcademyModality(Map<String, dynamic> data) {
    final typeStr = data['martial_art_type'] as String? ?? 'jiuJitsu';
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    final beltConfigsData =
        (data['belt_configs'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    final beltConfigs = beltConfigsData.map((b) {
      return BeltConfig(
        beltId: b['belt_id'] as String? ?? '',
        minClasses: b['min_classes'] as int? ?? 0,
        minMonths: b['min_months'] as int?,
        minClassesPerDegree: b['min_classes_per_degree'] as int?,
        requiresExam: b['requires_exam'] as bool? ?? false,
        examFee: (b['exam_fee'] as num?)?.toDouble(),
        notes: b['notes'] as String?,
      );
    }).toList();

    final graduationConfig = GraduationConfig(
      martialArtType: type,
      belts: beltConfigs,
      useDefaultConfig: data['use_default_graduation'] as bool? ?? true,
      configuredBy: null,
      lastUpdated: data['graduation_updated_at'] != null
          ? DateTime.tryParse(data['graduation_updated_at'].toString())
          : null,
    );

    final teacherIds =
        (data['teacher_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return AcademyModality(
      id: data['id'] as String? ?? '',
      type: type,
      masterId: (data['master_id'] as String?),
      teacherIds: teacherIds,
      instructorIds: const [],
      graduationConfig: graduationConfig,
      isActive: data['is_active'] as bool? ?? true,
    );
  }
}

