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

    switch (result) {
      case Success<UserProfile>(:final data):
        if (data.email.isNotEmpty) {
          _profile = data;
        } else {
          // Perfil vazio, criar inicial e salvar no banco
          _profile = UserProfile(
            id: userId,
            email: email ?? '',
            displayName: displayName,
            photoUrl: photoUrl,
          );
          // Salva o perfil no banco de dados para que exista um registro
          await _profileRepository.saveProfile(_profile);
        }
        _isLoading = false;
        _error = null;
      case Failure<UserProfile>(:final message):
        _error = message;
        _isLoading = false;
    }

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
        debugPrint('[ProfileService] ✅ Foto uploadada com sucesso. URL: $url');
        // Atualiza o perfil local com a nova URL
        _profile = _profile.copyWith(photoUrl: url);
        debugPrint('[ProfileService] Perfil local atualizado. photoUrl: ${_profile.photoUrl}');
        notifyListeners();
        
        // NÃO recarrega do servidor aqui para não perder a URL
        // O refresh será feito após salvar o perfil completo
      },
      onFailure: (failure) {
        debugPrint('[ProfileService] ❌ Erro no upload da foto: ${failure.message}');
      },
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

