import 'package:firebase_auth/firebase_auth.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/services/firebase_auth_service.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

/// Repository de autenticação
/// Fonte única da verdade para autenticação
abstract class AuthRepository {
  /// Stream de mudanças no estado de autenticação
  Stream<AppUser?> get authStateChanges;

  /// Usuário atual
  AppUser? get currentUser;

  /// Login com email e senha
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Cadastro com email e senha
  Future<Result<AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Envia email para redefinir senha
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Logout
  Future<Result<void>> signOut();
}

/// Implementação do AuthRepository usando Firebase
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthService authService})
      : _authService = authService;

  final FirebaseAuthService _authService;

  @override
  Stream<AppUser?> get authStateChanges {
    return _authService.authStateChanges.map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser {
    return _mapFirebaseUser(_authService.currentUser);
  }

  @override
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        return Result.failure(
          const Failure(message: 'Falha ao fazer login', code: 'unknown'),
        );
      }

      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseError(e));
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro inesperado: ${e.toString()}', code: 'unknown'),
      );
    }
  }

  @override
  Future<Result<AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Atualiza o nome se fornecido
      if (displayName != null && displayName.isNotEmpty) {
        await _authService.updateDisplayName(displayName);
        await _authService.reloadUser();
      }

      // Envia email de verificação
      await _authService.sendEmailVerification();

      final user = _mapFirebaseUser(_authService.currentUser);
      if (user == null) {
        return Result.failure(
          const Failure(message: 'Falha ao criar conta', code: 'unknown'),
        );
      }

      return Result.success(user.copyWith(displayName: displayName));
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseError(e));
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro inesperado: ${e.toString()}', code: 'unknown'),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseError(e));
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro inesperado: ${e.toString()}', code: 'unknown'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _authService.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        Failure(message: 'Erro ao fazer logout: ${e.toString()}'),
      );
    }
  }

  /// Converte User do Firebase para AppUser
  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;

    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  /// Converte erros do Firebase para Failure
  Failure _mapFirebaseError(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'Email inválido',
      'user-disabled' => 'Esta conta foi desativada',
      'user-not-found' => 'Usuário não encontrado',
      'wrong-password' => 'Senha incorreta',
      'invalid-credential' => 'Email ou senha incorretos',
      'email-already-in-use' => 'Este email já está em uso',
      'operation-not-allowed' => 'Operação não permitida',
      'weak-password' => 'A senha é muito fraca',
      'too-many-requests' =>
        'Muitas tentativas. Tente novamente mais tarde',
      'network-request-failed' => 'Erro de conexão. Verifique sua internet',
      _ => e.message ?? 'Erro desconhecido',
    };

    return Failure(message: message, code: e.code);
  }
}

