import 'package:firebase_auth/firebase_auth.dart';

/// Service para acesso ao Firebase Auth
/// Encapsula todas as chamadas ao Firebase Authentication
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// Stream de mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuário atual (pode ser null)
  User? get currentUser => _firebaseAuth.currentUser;

  /// Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Cadastro com email e senha
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Atualiza o nome de exibição do usuário
  Future<void> updateDisplayName(String displayName) async {
    await _firebaseAuth.currentUser?.updateDisplayName(displayName);
  }

  /// Envia email de verificação
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  /// Envia email para redefinir senha
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Recarrega os dados do usuário
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }
}

