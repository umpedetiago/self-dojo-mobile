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
    createFirebaseAccount = Command0(_createFirebaseAccount);
    createSupabaseProfile = Command1(_createSupabaseProfile);
  }

  final AuthRepository _authRepository;

  // Commands separados para as duas etapas
  late final Command0<AppUser> createFirebaseAccount;
  late final Command1<void, AppUser> createSupabaseProfile;

  // Estado do formulário
  String _name = '';
  String get name => _name;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _acceptedTerms = false;
  bool get acceptedTerms => _acceptedTerms;

  // Role selecionado
  UserRole _selectedRole = UserRole.student;
  UserRole get selectedRole => _selectedRole;

  /// Roles disponíveis para seleção no cadastro (apenas Student e Owner)
  static const List<UserRole> availableRoles = [
    UserRole.student,
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

  /// Verifica se a modalidade é obrigatória (não é para owners que criam academia)
  bool get isMartialArtRequired => _selectedRole != UserRole.owner;

  /// Verifica se a modalidade foi selecionada (quando obrigatória)
  bool get isMartialArtValid => !isMartialArtRequired || _selectedMartialArt != null;

  bool get isFormValid =>
      isNameValid &&
      isEmailValid &&
      isPasswordValid &&
      isMartialArtValid &&
      _acceptedTerms;

  String? get passwordError {
    if (_password.isEmpty) return null;
    if (_password.length < 6) return 'Mínimo 6 caracteres';
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

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
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

  // ETAPA 1: Criar conta no Firebase (autenticação)
  Future<Result<AppUser>> _createFirebaseAccount() async {
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
    );

    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (failure) => _errorMessage = failure.message,
    );

    notifyListeners();
    return result;
  }

  // ETAPA 2: Criar perfil no Supabase (banco de dados)
  Future<Result<void>> _createSupabaseProfile(AppUser user) async {
    final result = await _authRepository.createProfile(
      userId: user.id,
      email: user.email,
      displayName: user.displayName ?? _name.trim(),
      role: _selectedRole,
      martialArtType: _selectedMartialArt ??
          (_selectedRole == UserRole.owner ? null : MartialArtType.jiuJitsu),
    );

    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (failure) => _errorMessage = failure.message,
    );

    notifyListeners();
    return result;
  }

}

