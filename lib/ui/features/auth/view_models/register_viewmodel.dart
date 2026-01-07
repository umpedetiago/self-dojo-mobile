import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

/// ViewModel da tela de Cadastro
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    register = Command0(_register);
  }

  final AuthRepository _authRepository;

  // Command
  late final Command0<AppUser> register;

  // Estado do formulário
  String _name = '';
  String get name => _name;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirmPassword = true;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  bool _acceptedTerms = false;
  bool get acceptedTerms => _acceptedTerms;

  // Role selecionado
  UserRole _selectedRole = UserRole.student;
  UserRole get selectedRole => _selectedRole;

  /// Roles disponíveis para seleção no cadastro
  static const List<UserRole> availableRoles = [
    UserRole.student,
    UserRole.instructor,
    UserRole.teacher,
    UserRole.owner,
  ];

  // Modalidade selecionada
  MartialArtType? _selectedMartialArt;
  MartialArtType? get selectedMartialArt => _selectedMartialArt;

  /// Modalidades disponíveis para seleção no cadastro
  static List<MartialArt> get availableMartialArts => MartialArtsConfig.all;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Validação
  bool get isNameValid => _name.trim().length >= 2;

  bool get isEmailValid =>
      _email.isNotEmpty &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);

  bool get isPasswordValid => _password.length >= 6;

  bool get isConfirmPasswordValid =>
      _confirmPassword.isNotEmpty && _confirmPassword == _password;

  /// Verifica se a modalidade é obrigatória (não é para owners que criam academia)
  bool get isMartialArtRequired => _selectedRole != UserRole.owner;

  /// Verifica se a modalidade foi selecionada (quando obrigatória)
  bool get isMartialArtValid => !isMartialArtRequired || _selectedMartialArt != null;

  bool get isFormValid =>
      isNameValid &&
      isEmailValid &&
      isPasswordValid &&
      isConfirmPasswordValid &&
      isMartialArtValid &&
      _acceptedTerms;

  String? get passwordError {
    if (_password.isEmpty) return null;
    if (_password.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? get confirmPasswordError {
    if (_confirmPassword.isEmpty) return null;
    if (_confirmPassword != _password) return 'As senhas não coincidem';
    return null;
  }

  // Actions
  void setName(String value) {
    _name = value;
    _errorMessage = null;
    notifyListeners();
  }

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

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void toggleAcceptedTerms() {
    _acceptedTerms = !_acceptedTerms;
    notifyListeners();
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    // Se mudou para owner, limpa a modalidade (owner cria academia depois)
    if (role == UserRole.owner) {
      _selectedMartialArt = null;
    }
    notifyListeners();
  }

  void setSelectedMartialArt(MartialArtType? type) {
    _selectedMartialArt = type;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Registro
  Future<Result<AppUser>> _register() async {
    if (!isFormValid) {
      final message = !_acceptedTerms
          ? 'Aceite os termos de uso para continuar'
          : 'Preencha todos os campos corretamente';

      return Result.failure(Failure(message: message));
    }

    final result = await _authRepository.createUserWithEmailAndPassword(
      email: _email,
      password: _password,
      displayName: _name.trim(),
      role: _selectedRole,
      martialArtType: _selectedMartialArt,
    );

    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (failure) => _errorMessage = failure.message,
    );

    notifyListeners();
    return result;
  }

}

