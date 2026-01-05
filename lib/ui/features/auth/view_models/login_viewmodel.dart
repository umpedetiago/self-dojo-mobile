import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

/// ViewModel da tela de Login
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    login = Command0(_login);
    forgotPassword = Command1(_forgotPassword);
  }

  final AuthRepository _authRepository;

  // Commands
  late final Command0<AppUser> login;
  late final Command1<void, String> forgotPassword;

  // Estado do formulário
  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Validação
  bool get isEmailValid =>
      _email.isNotEmpty &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);

  bool get isPasswordValid => _password.length >= 6;

  bool get isFormValid => isEmailValid && isPasswordValid;

  // Actions
  void setEmail(String value) {
    _email = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Login
  Future<Result<AppUser>> _login() async {
    if (!isFormValid) {
      return Result.failure(
        const Failure(message: 'Preencha todos os campos corretamente'),
      );
    }

    final result = await _authRepository.signInWithEmailAndPassword(
      email: _email,
      password: _password,
    );

    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (failure) => _errorMessage = failure.message,
    );

    notifyListeners();
    return result;
  }

  // Esqueci minha senha
  Future<Result<void>> _forgotPassword(String email) async {
    if (email.isEmpty) {
      return Result.failure(
        const Failure(message: 'Digite seu email'),
      );
    }

    return _authRepository.sendPasswordResetEmail(email);
  }

}

