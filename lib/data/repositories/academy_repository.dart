import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/services/academy_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/subscription.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:uuid/uuid.dart';

/// Repository de academias
abstract class AcademyRepository {
  /// Obtém academia por ID
  Future<Result<Academy>> getAcademy(String academyId);

  /// Stream de mudanças na academia
  Stream<Academy?> watchAcademy(String academyId);

  /// Cria nova academia (com trial)
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
  });

  /// Atualiza academia
  Future<Result<void>> updateAcademy(Academy academy);

  /// Busca academias
  Future<Result<List<Academy>>> searchAcademies(String query);

  /// Obtém academia do owner
  Future<Result<Academy?>> getOwnerAcademy(String ownerId);

  /// Adiciona modalidade
  Future<Result<void>> addModality(
    String academyId,
    MartialArtType type,
  );

  /// Remove modalidade
  Future<Result<void>> removeModality(
    String academyId,
    MartialArtType type,
  );

  /// Define mestre de modalidade
  Future<Result<void>> setModalityMaster(
    String academyId,
    MartialArtType type,
    String? masterId,
  );

  /// Atualiza configuração de graduação
  Future<Result<void>> updateGraduationConfig(
    String academyId,
    MartialArtType type,
    GraduationConfig config,
  );

  /// Conta alunos
  Future<Result<int>> countStudents(String academyId);
}

/// Implementação do AcademyRepository
class AcademyRepositoryImpl implements AcademyRepository {
  AcademyRepositoryImpl({
    required AcademyService academyService,
  }) : _academyService = academyService;

  final AcademyService _academyService;
  final _uuid = const Uuid();

  @override
  Future<Result<Academy>> getAcademy(String academyId) async {
    try {
      final doc = await _academyService.getAcademy(academyId);

      if (!doc.exists || doc.data() == null) {
        return Result.failure(
          const Failure(message: 'Academia não encontrada', code: 'not-found'),
        );
      }

      final academy = Academy.fromMap(doc.data()!);
      return Result.success(academy);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar academia: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<Academy?> watchAcademy(String academyId) {
    return _academyService.watchAcademy(academyId).map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Academy.fromMap(doc.data()!);
    });
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
      // Verifica se owner já tem academia
      final existingResult = await getOwnerAcademy(ownerId);
      final hasExisting = existingResult.fold(
        onSuccess: (academy) => academy != null,
        onFailure: (_) => false,
      );

      if (hasExisting) {
        return Result.failure(
          const Failure(
            message: 'Você já possui uma academia cadastrada',
            code: 'already-exists',
          ),
        );
      }

      final academyId = _uuid.v4();
      final now = DateTime.now();

      // Cria modalidades com config padrão
      final academyModalities = modalities.map((type) {
        return AcademyModality(
          type: type,
          graduationConfig: GraduationConfig(
            martialArtType: type,
            useDefaultConfig: true,
          ),
        );
      }).toList();

      // Cria academia com trial
      final academy = Academy(
        id: academyId,
        name: name,
        ownerId: ownerId,
        description: description,
        address: address,
        city: city,
        state: state,
        phone: phone,
        email: email,
        modalities: academyModalities,
        subscription: SubscriptionInfo.trial(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _academyService.setAcademy(academyId, academy.toMap());

      return Result.success(academy);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar academia: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateAcademy(Academy academy) async {
    try {
      final updatedAcademy = academy.copyWith(updatedAt: DateTime.now());
      await _academyService.setAcademy(academy.id, updatedAcademy.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar academia: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Academy>>> searchAcademies(String query) async {
    try {
      final snapshot = await _academyService.searchByName(query);
      final academies =
          snapshot.docs.map((doc) => Academy.fromMap(doc.data())).toList();
      return Result.success(academies);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar academias: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Academy?>> getOwnerAcademy(String ownerId) async {
    try {
      final snapshot = await _academyService.getByOwner(ownerId);
      if (snapshot.docs.isEmpty) {
        return Result.success(null);
      }
      final academy = Academy.fromMap(snapshot.docs.first.data());
      return Result.success(academy);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar academia: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> addModality(
    String academyId,
    MartialArtType type,
  ) async {
    try {
      final result = await getAcademy(academyId);

      return result.fold(
        onSuccess: (academy) async {
          // Verifica limite do plano
          if (!academy.canAddModality()) {
            return Result.failure<void>(
              const Failure(
                message: 'Limite de modalidades atingido no seu plano',
                code: 'limit-reached',
              ),
            );
          }

          // Verifica se já existe
          if (academy.hasModality(type)) {
            return Result.failure<void>(
              const Failure(
                message: 'Esta modalidade já existe na academia',
                code: 'already-exists',
              ),
            );
          }

          final newModality = AcademyModality(
            type: type,
            graduationConfig: GraduationConfig(
              martialArtType: type,
              useDefaultConfig: true,
            ),
          );

          final updatedAcademy = academy.copyWith(
            modalities: [...academy.modalities, newModality],
          );

          return updateAcademy(updatedAcademy);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao adicionar modalidade: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> removeModality(
    String academyId,
    MartialArtType type,
  ) async {
    try {
      final result = await getAcademy(academyId);

      return result.fold(
        onSuccess: (academy) async {
          final updatedModalities =
              academy.modalities.where((m) => m.type != type).toList();

          if (updatedModalities.length == academy.modalities.length) {
            return Result.failure<void>(
              const Failure(
                message: 'Modalidade não encontrada',
                code: 'not-found',
              ),
            );
          }

          final updatedAcademy =
              academy.copyWith(modalities: updatedModalities);
          return updateAcademy(updatedAcademy);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao remover modalidade: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> setModalityMaster(
    String academyId,
    MartialArtType type,
    String? masterId,
  ) async {
    try {
      final result = await getAcademy(academyId);

      return result.fold(
        onSuccess: (academy) async {
          final updatedModalities = academy.modalities.map((m) {
            if (m.type == type) {
              return m.copyWith(masterId: masterId);
            }
            return m;
          }).toList();

          final updatedAcademy =
              academy.copyWith(modalities: updatedModalities);
          return updateAcademy(updatedAcademy);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao definir mestre: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateGraduationConfig(
    String academyId,
    MartialArtType type,
    GraduationConfig config,
  ) async {
    try {
      final result = await getAcademy(academyId);

      return result.fold(
        onSuccess: (academy) async {
          final updatedModalities = academy.modalities.map((m) {
            if (m.type == type) {
              return m.copyWith(
                graduationConfig: config.copyWith(lastUpdated: DateTime.now()),
              );
            }
            return m;
          }).toList();

          final updatedAcademy =
              academy.copyWith(modalities: updatedModalities);
          return updateAcademy(updatedAcademy);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar graduação: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<int>> countStudents(String academyId) async {
    try {
      final count = await _academyService.countStudents(academyId);
      return Result.success(count);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao contar alunos: ${e.toString()}'),
      );
    }
  }
}
