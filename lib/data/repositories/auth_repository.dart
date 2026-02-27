import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

/// Repository de autenticação
/// Fonte única da verdade para autenticação
abstract class AuthRepository {
  /// Restaura sessão persistida e emite o estado inicial.
  Future<void> restoreSession();

  /// Stream de mudanças no estado de autenticação
  Stream<AppUser?> get authStateChanges;

  /// Usuário atual
  AppUser? get currentUser;

  /// Login com email e senha
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Cadastro com email e senha (apenas Firebase - autenticação)
  Future<Result<AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Cria perfil completo no Supabase (após autenticação)
  Future<Result<void>> createProfile({
    required String userId,
    required String email,
    String? displayName,
    required UserRole role,
    MartialArtType? martialArtType,
  });

  /// Envia email para redefinir senha
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Logout
  Future<Result<void>> signOut();
}

