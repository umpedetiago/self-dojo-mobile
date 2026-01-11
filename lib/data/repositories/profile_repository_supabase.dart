import 'dart:io';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/student_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';

/// Implementação do ProfileRepository usando Supabase
class ProfileRepositorySupabase implements ProfileRepository {
  ProfileRepositorySupabase({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<UserProfile>> getProfile(String firebaseUid) async {
    try {
      final data = await _supabaseService.getUserByFirebaseUid(firebaseUid);

      if (data == null) {
        // Retorna perfil vazio para usuário novo
        return Result.success(UserProfile(
          id: firebaseUid,
          email: '',
        ));
      }

      // Busca as modalidades matriculadas do aluno
      final userId = data['id'] as String;
      final enrolledModalitiesData =
          await _supabaseService.getUserEnrolledModalities(userId);
      final enrolledModalities =
          enrolledModalitiesData.map(_mapToStudentModality).toList();

      final profile = _mapToProfile(data, enrolledModalities: enrolledModalities);
      return Result.success(profile);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao buscar perfil: $e'));
    }
  }

  @override
  Future<Result<void>> saveProfile(UserProfile profile) async {
    try {
      await _supabaseService.upsertUser(_profileToMap(profile));
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao salvar perfil: $e'));
    }
  }

  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    try {
      // Busca o ID do usuário pelo firebase_uid
      final existing = await _supabaseService.getUserByFirebaseUid(profile.id);

      if (existing != null) {
        await _supabaseService.updateUser(
          existing['id'],
          _profileToMap(profile, includeFirebaseUid: false),
        );
      } else {
        await _supabaseService.upsertUser(_profileToMap(profile));
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro ao atualizar perfil: $e'));
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String firebaseUid) async* {
    // Supabase não suporta stream diretamente em queries com where
    // Fazemos um fetch inicial
    final result = await getProfile(firebaseUid);
    yield result.fold(
      onSuccess: (profile) => profile,
      onFailure: (_) => null,
    );
  }

  @override
  Future<Result<String>> uploadProfileImage(String userId, File image) async {
    try {
      final path =
          'profiles/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await _supabaseService.uploadFile(
        bucket: 'avatars',
        path: path,
        file: image,
      );

      return result.fold(
        onSuccess: (url) async {
          // Atualiza o perfil com a nova URL
          final existing = await _supabaseService.getUserByFirebaseUid(userId);
          if (existing != null) {
            await _supabaseService
                .updateUser(existing['id'], {'photo_url': url});
          }
          return Result.success(url);
        },
        onFailure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(Failure(message: 'Erro no upload da imagem: $e'));
    }
  }

  // ============================================
  // MAPPERS
  // ============================================

  Map<String, dynamic> _profileToMap(UserProfile profile,
      {bool includeFirebaseUid = true}) {
    final map = <String, dynamic>{
      'email': profile.email,
      'display_name': profile.displayName,
      'photo_url': profile.photoUrl,
      'role': profile.role.name,
      'martial_art_type': profile.martialArtType?.name,
      'legacy_belt_id': profile.graduation?.beltId,
      'legacy_degree': profile.graduation?.degree,
      'legacy_total_classes': profile.totalClasses,
      'legacy_has_aparadores': profile.graduation?.hasAparadores,
    };

    if (includeFirebaseUid) {
      map['firebase_uid'] = profile.id;
    }

    return map;
  }

  UserProfile _mapToProfile(
    Map<String, dynamic> data, {
    List<StudentModality> enrolledModalities = const [],
  }) {
    // Parse role
    final roleStr = data['role'] as String? ?? 'student';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.student,
    );

    // Parse martial art type (pode ser null para owners sem modalidade definida)
    final martialArtStr = data['martial_art_type'] as String?;
    final martialArtType = martialArtStr != null
        ? MartialArtType.values.firstWhere(
            (t) => t.name == martialArtStr,
            orElse: () => MartialArtType.jiuJitsu,
          )
        : null;

    // Parse graduation
    UserGraduation? graduation;
    if (data['legacy_belt_id'] != null) {
      graduation = UserGraduation(
        beltId: data['legacy_belt_id'] as String,
        degree: data['legacy_degree'] as int? ?? 0,
        classesAtCurrentBelt: 0,
        hasAparadores: data['legacy_has_aparadores'] as bool?,
      );
    }

    return UserProfile(
      id: data['firebase_uid'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String?,
      photoUrl: data['photo_url'] as String?,
      role: role,
      martialArtType: martialArtType,
      graduation: graduation,
      enrolledModalities: enrolledModalities,
      totalClasses: data['legacy_total_classes'] as int? ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  /// Converte dados do banco para StudentModality
  StudentModality _mapToStudentModality(Map<String, dynamic> data) {
    // Parse tipo da arte marcial
    final typeStr = data['martial_art_type'] as String? ?? 'jiuJitsu';
    final type = MartialArtType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MartialArtType.jiuJitsu,
    );

    // Parse graduação atual
    final graduation = UserGraduation(
      beltId: data['belt_id'] as String? ?? '',
      degree: data['degree'] as int? ?? 0,
      classesAtCurrentBelt: data['total_classes_at_current_belt'] as int? ?? 0,
      promotionDate: data['last_promotion_at'] != null
          ? DateTime.tryParse(data['last_promotion_at'] as String)
          : null,
    );

    // Parse histórico de graduações
    final historyData = data['graduation_history'] as List<dynamic>? ?? [];
    final graduationHistory = historyData.map((h) {
      final historyMap = h as Map<String, dynamic>;
      return GraduationHistory(
        beltId: historyMap['new_belt_id'] as String? ?? '',
        degree: historyMap['new_degree'] as int? ?? 0,
        date: DateTime.tryParse(historyMap['promoted_at'] as String? ?? '') ??
            DateTime.now(),
        notes: historyMap['notes'] as String?,
      );
    }).toList();

    return StudentModality(
      type: type,
      assignedTeacherId: data['assigned_teacher_id'] as String?,
      graduation: graduation,
      graduationHistory: graduationHistory,
      totalClasses: data['total_classes'] as int? ?? 0,
      enrolledAt: DateTime.tryParse(data['enrolled_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
