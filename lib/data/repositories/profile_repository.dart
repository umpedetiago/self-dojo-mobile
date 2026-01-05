import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/services/firestore_service.dart';
import 'package:self_dojo_mobile/data/services/storage_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Repository de perfil do usuário
abstract class ProfileRepository {
  /// Obtém perfil do usuário
  Future<Result<UserProfile>> getProfile(String userId);

  /// Stream de mudanças no perfil
  Stream<UserProfile?> watchProfile(String userId);

  /// Cria perfil inicial
  Future<Result<UserProfile>> createProfile({
    required String userId,
    required String email,
    String? displayName,
    MartialArtType martialArtType = MartialArtType.jiuJitsu,
  });

  /// Atualiza perfil
  Future<Result<void>> updateProfile(UserProfile profile);

  /// Atualiza foto de perfil
  Future<Result<String>> updateProfilePhoto({
    required String userId,
    required File photo,
  });

  /// Registra uma aula (check-in)
  Future<Result<void>> registerClass(String userId);

  /// Promove usuário para próxima graduação
  Future<Result<void>> promote({
    required String userId,
    required String newBeltId,
    int degree = 0,
    String? notes,
  });

  /// Adiciona competição
  Future<Result<void>> addCompetition({
    required String userId,
    required Competition competition,
  });
}

/// Implementação do ProfileRepository
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required FirestoreService firestoreService,
    required StorageService storageService,
    FirebaseAuth? firebaseAuth,
  })  : _firestoreService = firestoreService,
        _storageService = storageService,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      final doc = await _firestoreService.getUser(userId);

      if (!doc.exists || doc.data() == null) {
        return Result.failure(
          const Failure(message: 'Perfil não encontrado', code: 'not-found'),
        );
      }

      final profile = UserProfile.fromMap(doc.data()!);
      return Result.success(profile);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao buscar perfil: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _firestoreService.watchUser(userId).map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserProfile.fromMap(doc.data()!);
    });
  }

  @override
  Future<Result<UserProfile>> createProfile({
    required String userId,
    required String email,
    String? displayName,
    MartialArtType martialArtType = MartialArtType.jiuJitsu,
  }) async {
    try {
      final martialArt = MartialArtsConfig.getByType(martialArtType);

      final profile = UserProfile(
        id: userId,
        email: email,
        displayName: displayName,
        martialArtType: martialArtType,
        graduation: UserGraduation.initial(martialArt.initialBelt.id),
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setUser(userId, profile.toMap());

      return Result.success(profile);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao criar perfil: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestoreService.setUser(profile.id, updatedProfile.toMap());

      // Atualiza nome no Firebase Auth se mudou
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null &&
          profile.displayName != null &&
          currentUser.displayName != profile.displayName) {
        await currentUser.updateDisplayName(profile.displayName);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar perfil: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<String>> updateProfilePhoto({
    required String userId,
    required File photo,
  }) async {
    try {
      // Faz upload da foto
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: userId,
        file: photo,
      );

      // Atualiza URL no Firestore
      await _firestoreService.updateUser(userId, {'photoUrl': photoUrl});

      // Atualiza foto no Firebase Auth
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePhotoURL(photoUrl);
      }

      return Result.success(photoUrl);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao atualizar foto: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> registerClass(String userId) async {
    try {
      await _firestoreService.incrementClassCount(userId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao registrar aula: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> promote({
    required String userId,
    required String newBeltId,
    int degree = 0,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      // Nova graduação
      final newGraduation = UserGraduation(
        beltId: newBeltId,
        degree: degree,
        promotionDate: now,
        classesAtCurrentBelt: 0,
      );

      // Adiciona ao histórico
      final historyEntry = GraduationHistory(
        beltId: newBeltId,
        degree: degree,
        date: now,
        notes: notes,
      );

      await _firestoreService.setUser(userId, {
        'graduation': newGraduation.toMap(),
        'updatedAt': now.toIso8601String(),
      });

      await _firestoreService.addGraduationHistory(
        userId,
        historyEntry.toMap(),
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao promover: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> addCompetition({
    required String userId,
    required Competition competition,
  }) async {
    try {
      await _firestoreService.addCompetition(userId, competition.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao adicionar competição: ${e.toString()}'),
      );
    }
  }
}

