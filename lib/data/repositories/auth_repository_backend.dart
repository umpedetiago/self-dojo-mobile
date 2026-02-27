import 'dart:async';

import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/auth_session_store.dart';
import 'package:self_dojo_mobile/data/services/backend_auth_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

class AuthRepositoryBackend implements AuthRepository {
  AuthRepositoryBackend({
    required BackendAuthService authService,
    required AuthSessionStore sessionStore,
    required ProfileRepository profileRepository,
  })  : _authService = authService,
        _sessionStore = sessionStore,
        _profileRepository = profileRepository {
    _sessionStore.sessionChanges.listen(
      _handleSessionChange,
    );
  }

  final BackendAuthService _authService;
  final AuthSessionStore _sessionStore;
  final ProfileRepository _profileRepository;
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;
  bool _restored = false;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> restoreSession() async {
    if (_restored) {
      _authController.add(_currentUser);
      return;
    }

    _restored = true;
    final sessionUser = _sessionStore.user;
    if (sessionUser != null &&
        _sessionStore.token != null &&
        _sessionStore.token!.isNotEmpty) {
      _currentUser = sessionUser;
      _authController.add(_currentUser);
      return;
    }

    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);
    return result.fold(
      onSuccess: (data) async {
        await _persistSession(data.user, data.token);
        return Result.success(data.user);
      },
      onFailure: Result.failure,
    );
  }

  @override
  Future<Result<AppUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final result = await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return result.fold(
      onSuccess: (data) async {
        await _persistSession(data.user, data.token);
        return Result.success(data.user);
      },
      onFailure: Result.failure,
    );
  }

  @override
  Future<Result<void>> createProfile({
    required String userId,
    required String email,
    String? displayName,
    required UserRole role,
    MartialArtType? martialArtType,
  }) async {
    final backendResult = await _authService.updateProfile(
      displayName: displayName,
      role: role,
      martialArtType: martialArtType,
    );

    if (!backendResult.isSuccess) {
      return backendResult;
    }

    final profile = UserProfile(
      id: userId,
      email: email,
      displayName: displayName,
      role: role,
      martialArtType: martialArtType ?? MartialArtType.jiuJitsu,
      createdAt: DateTime.now(),
    );
    final mirrored = await _profileRepository.saveProfile(profile);
    return mirrored.fold(
      onSuccess: (_) => Result.success(null),
      onFailure: (_) => Result.success(null),
    );
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) {
    return _authService.forgotPassword(email);
  }

  @override
  Future<Result<void>> signOut() async {
    await _authService.logout();
    await _sessionStore.clear();
    _currentUser = null;
    _authController.add(null);
    return Result.success(null);
  }

  Future<void> _persistSession(AppUser user, String token) async {
    await _sessionStore.saveSession(AuthSession(token: token, user: user));
    _currentUser = user;
    _authController.add(user);
  }

  void _handleSessionChange(AuthSession? session) {
    if (session == null) {
      if (_currentUser != null) {
        _currentUser = null;
        _authController.add(null);
      }
      return;
    }

    if (_currentUser != session.user) {
      _currentUser = session.user;
      _authController.add(_currentUser);
    }
  }
}

