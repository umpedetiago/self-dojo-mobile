import 'dart:io';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Repository de perfil do usuário
abstract class ProfileRepository {
  /// Obtém perfil do usuário
  Future<Result<UserProfile>> getProfile(String userId);

  /// Stream de mudanças no perfil
  Stream<UserProfile?> watchProfile(String userId);

  /// Cria ou atualiza perfil
  Future<Result<void>> saveProfile(UserProfile profile);

  /// Atualiza perfil
  Future<Result<void>> updateProfile(UserProfile profile);

  /// Atualiza foto de perfil
  Future<Result<String>> uploadProfileImage(String userId, File image);
}
