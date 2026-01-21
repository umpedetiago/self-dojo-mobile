import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/subscription.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Implementação do AcademyRepository usando Supabase
class AcademyRepositorySupabase implements AcademyRepository {
  AcademyRepositorySupabase({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<Academy?>> getAcademy(String academyId) async {
    try {
      final data = await _supabaseService.getAcademy(academyId);
      if (data == null) return Result.success(null);

      final academy = _mapToAcademy(data);
      return Result.success(academy);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar academia: $e'));
    }
  }

  @override
  Future<Result<Academy?>> getOwnerAcademy(String ownerFirebaseUid) async {
    try {
      final data = await _supabaseService.getOwnerAcademy(ownerFirebaseUid);
      if (data == null) return Result.success(null);

      final academy = _mapToAcademy(data);
      return Result.success(academy);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar academia: $e'));
    }
  }

  @override
  Future<Result<List<Academy>>> getOwnerAcademies(String ownerFirebaseUid) async {
    try {
      final data = await _supabaseService.getOwnerAcademies(ownerFirebaseUid);
      final academies = data.map(_mapToAcademy).toList();
      return Result.success(academies);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar academias do owner: $e'),
      );
    }
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
    try {
      // Primeiro busca o user_id pelo firebase_uid
      final user = await _supabaseService.getUserByFirebaseUid(ownerId);
      if (user == null) {
        return Result.failure(Failure(message: 'Usuário não encontrado'));
      }

      final userId = user['id'] as String;

      // Configura trial de 7 dias
      final now = DateTime.now();
      final trialEnds = now.add(const Duration(days: 7));

      // Cria a academia
      final academyData = <String, dynamic>{
        'owner_id': userId,
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'state': state,
        'phone': phone,
        'email': email,
        'subscription_plan': 'trial',
        'subscription_started_at': now.toIso8601String(),
        'subscription_ends_at': trialEnds.toIso8601String(),
        'max_students': 10,
        'max_teachers': 3,
        'max_modalities': 3,
      };

      final academyResponse = await _supabaseService.createAcademy(academyData);
      final academyId = academyResponse['id'] as String;

      // Cria as modalidades
      for (final type in modalities) {
        await _supabaseService.addModality({
          'academy_id': academyId,
          'martial_art_type': type.name,
          'use_default_graduation': true,
        });
      }

      // Busca academia completa
      final result = await getAcademy(academyId);
      return result.fold(
        onSuccess: (academy) {
          if (academy == null) {
            return Result.failure(
                Failure(message: 'Academia não encontrada após criação'));
          }
          return Result.success(academy);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao criar academia: $e'));
    }
  }

  @override
  Future<Result<void>> updateAcademy(Academy academy) async {
    try {
      await _supabaseService.updateAcademy(academy.id, {
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
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao atualizar academia: $e'));
    }
  }

  @override
  Stream<Academy?> watchAcademy(String academyId) {
    return _supabaseService.watchAcademy(academyId).map((data) {
      if (data == null) return null;
      return _mapToAcademy(data);
    });
  }

  @override
  Future<Result<void>> addModality(
      String academyId, MartialArtType type) async {
    try {
      await _supabaseService.addModality({
        'academy_id': academyId,
        'martial_art_type': type.name,
        'use_default_graduation': true,
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao adicionar modalidade: $e'));
    }
  }

  @override
  Future<Result<void>> removeModality(
      String academyId, MartialArtType type) async {
    try {
      final modalities = await _supabaseService.getAcademyModalities(academyId);
      final modality = modalities.firstWhere(
        (m) => m['martial_art_type'] == type.name,
        orElse: () => <String, dynamic>{},
      );

      if (modality.isNotEmpty) {
        await _supabaseService.deleteModality(modality['id']);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao remover modalidade: $e'));
    }
  }

  @override
  Future<Result<void>> setModalityMaster(
    String academyId,
    MartialArtType type,
    String? masterId,
  ) async {
    try {
      final modalities = await _supabaseService.getAcademyModalities(academyId);
      final modality = modalities.firstWhere(
        (m) => m['martial_art_type'] == type.name,
        orElse: () => <String, dynamic>{},
      );

      if (modality.isNotEmpty) {
        await _supabaseService.updateModality(modality['id'], {
          'master_id': masterId,
        });
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao definir mestre: $e'));
    }
  }

  @override
  Future<Result<void>> updateGraduationConfig(
    String academyId,
    MartialArtType type,
    GraduationConfig config,
  ) async {
    try {
      final modalities = await _supabaseService.getAcademyModalities(academyId);
      final modality = modalities.firstWhere(
        (m) => m['martial_art_type'] == type.name,
        orElse: () => <String, dynamic>{},
      );

      if (modality.isEmpty) {
        return Result.failure(Failure(message: 'Modalidade não encontrada'));
      }

      final modalityId = modality['id'] as String;

      // Atualiza configuração da modalidade
      await _supabaseService.updateModality(modalityId, {
        'use_default_graduation': config.useDefaultConfig,
        'graduation_updated_at': DateTime.now().toIso8601String(),
      });

      // Atualiza belt configs
      if (!config.useDefaultConfig) {
        final beltConfigs = config.belts
            .map((b) => {
                  'belt_id': b.beltId,
                  'min_classes': b.minClasses,
                  'min_months': b.minMonths,
                  'min_classes_per_degree': b.minClassesPerDegree,
                  'requires_exam': b.requiresExam,
                  'exam_fee': b.examFee,
                  'notes': b.notes,
                })
            .toList();

        await _supabaseService.upsertBeltConfigs(modalityId, beltConfigs);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
          Failure(message: 'Erro ao atualizar configuração: $e'));
    }
  }

  @override
  Future<Result<int>> countStudents(String academyId) async {
    try {
      final count = await _supabaseService.countAcademyMembers(
        academyId,
        status: 'approved',
      );
      return Result.success(count);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao contar alunos: $e'));
    }
  }

  @override
  Future<Result<int>> countPendingRequests(String academyId) async {
    try {
      final count = await _supabaseService.countPendingRequests(academyId);
      return Result.success(count);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao contar solicitações: $e'));
    }
  }

  // ============================================
  // MAPPERS
  // ============================================

  Academy _mapToAcademy(Map<String, dynamic> data) {
    // Parse modalities
    final modalitiesData = data['academy_modalities'] as List<dynamic>? ?? [];
    final modalities = modalitiesData.map((m) {
      return _mapToModality(m as Map<String, dynamic>);
    }).toList();

    // Parse subscription
    SubscriptionInfo? subscription;
    final subscriptionPlan = data['subscription_plan'] as String?;
    if (subscriptionPlan != null) {
      final isTrial = subscriptionPlan == 'trial';
      final plan = isTrial
          ? SubscriptionPlan.pro
          : SubscriptionPlan.values.firstWhere(
              (p) => p.name == subscriptionPlan,
              orElse: () => SubscriptionPlan.basic,
            );

      final startDate = data['subscription_started_at'] != null
          ? DateTime.parse(data['subscription_started_at'] as String)
          : DateTime.now();

      final endDate = data['subscription_ends_at'] != null
          ? DateTime.parse(data['subscription_ends_at'] as String)
          : null;

      subscription = SubscriptionInfo(
        plan: plan,
        status:
            isTrial ? SubscriptionStatus.trial : SubscriptionStatus.active,
        startDate: startDate,
        endDate: endDate,
        isTrial: isTrial,
        trialStartDate: isTrial ? startDate : null,
        trialEndDate: isTrial ? endDate : null,
      );
    }

    return Academy(
      id: data['id'] as String,
      name: data['name'] as String,
      ownerId: data['owner_id'] as String,
      logoUrl: data['logo_url'] as String?,
      description: data['description'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      modalities: modalities,
      subscription: subscription,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  AcademyModality _mapToModality(Map<String, dynamic> data) {
    final typeStr = data['martial_art_type'] as String;
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    // Parse belt configs
    final beltConfigsData = data['belt_configs'] as List<dynamic>? ?? [];
    final beltConfigs = beltConfigsData.map((b) {
      final bData = b as Map<String, dynamic>;
      return BeltConfig(
        beltId: bData['belt_id'] as String,
        minClasses: bData['min_classes'] as int? ?? 0,
        minMonths: bData['min_months'] as int?,
        minClassesPerDegree: bData['min_classes_per_degree'] as int?,
        requiresExam: bData['requires_exam'] as bool? ?? false,
        examFee: (bData['exam_fee'] as num?)?.toDouble(),
        notes: bData['notes'] as String?,
      );
    }).toList();

    final graduationConfig = GraduationConfig(
      martialArtType: type,
      belts: beltConfigs,
      useDefaultConfig: data['use_default_graduation'] as bool? ?? true,
      configuredBy: data['graduation_configured_by'] as String?,
      lastUpdated: data['graduation_updated_at'] != null
          ? DateTime.parse(data['graduation_updated_at'] as String)
          : null,
    );

    return AcademyModality(
      id: data['id'] as String,
      type: type,
      masterId: data['master_id'] as String?,
      teacherIds: const [],
      instructorIds: const [],
      graduationConfig: graduationConfig,
      isActive: data['is_active'] as bool? ?? true,
    );
  }
}
