import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

/// Estado da autenticação
enum AuthStatus {
  /// Estado inicial, verificando autenticação
  initial,

  /// Usuário autenticado
  authenticated,

  /// Usuário não autenticado
  unauthenticated,
}

/// ViewModel de autenticação global
/// Gerencia o estado de autenticação do usuário
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  AppUser _user = AppUser.empty;
  AppUser get user => _user;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing => _status == AuthStatus.initial;

  void _init() {
    // Escuta mudanças no estado de autenticação
    _authSubscription = _authRepository.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (_) => _setUnauthenticated(),
    );
  }

  void _onAuthStateChanged(AppUser? user) {
    if (user != null && user.isNotEmpty) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      _setUnauthenticated();
    }
    notifyListeners();
  }

  void _setUnauthenticated() {
    _user = AppUser.empty;
    _status = AuthStatus.unauthenticated;
  }

  /// Faz logout do usuário
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

