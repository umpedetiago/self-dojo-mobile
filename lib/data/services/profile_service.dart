import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Serviço centralizado de perfil que notifica todos os listeners sobre mudanças
class ProfileService extends ChangeNotifier {
  ProfileService({
    required ProfileRepository profileRepository,
  }) : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  // Estado do perfil atual
  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _currentUserId;

  /// Inicializa o serviço para um usuário específico
  Future<void> init(String userId, {String? email, String? displayName, String? photoUrl}) async {
    if (_currentUserId == userId && _profile.id == userId) {
      // Já inicializado para este usuário
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _profileRepository.getProfile(userId);

    result.fold(
      onSuccess: (profile) {
        if (profile.email.isNotEmpty) {
          _profile = profile;
        } else {
          // Perfil vazio, criar inicial
          _profile = UserProfile(
            id: userId,
            email: email ?? '',
            displayName: displayName,
            photoUrl: photoUrl,
          );
        }
        _isLoading = false;
        _error = null;
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
      },
    );

    notifyListeners();
  }

  /// Recarrega o perfil do servidor
  Future<void> refresh() async {
    if (_currentUserId == null) return;

    final result = await _profileRepository.getProfile(_currentUserId!);

    result.fold(
      onSuccess: (profile) {
        _profile = profile;
        _error = null;
      },
      onFailure: (failure) {
        _error = failure.message;
      },
    );

    notifyListeners();
  }

  /// Atualiza o perfil e notifica todos os listeners
  Future<Result<void>> updateProfile(UserProfile newProfile) async {
    final result = await _profileRepository.updateProfile(newProfile);

    result.fold(
      onSuccess: (_) {
        _profile = newProfile;
        notifyListeners();
      },
      onFailure: (_) {},
    );

    return result;
  }

  /// Atualiza a foto de perfil
  Future<Result<String>> updatePhoto(File photo) async {
    if (_currentUserId == null) {
      return Result.failure(const Failure(message: 'Usuário não autenticado'));
    }

    final result = await _profileRepository.uploadProfileImage(_currentUserId!, photo);

    result.fold(
      onSuccess: (url) {
        _profile = _profile.copyWith(photoUrl: url);
        notifyListeners();
      },
      onFailure: (_) {},
    );

    return result;
  }

  /// Limpa o estado (para logout)
  void clear() {
    _currentUserId = null;
    _profile = UserProfile.empty;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }
}

