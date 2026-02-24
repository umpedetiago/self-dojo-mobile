import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
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

  /// Define o perfil em memória logo após o cadastro (nome, arte marcial e role).
  /// Garante que os dados informados no registro apareçam na Home mesmo se o
  /// save no Supabase falhar ou atrasar.
  void setProfileAfterRegistration(UserProfile profile) {
    _currentUserId = profile.id;
    _profile = profile;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Inicializa o serviço para um usuário específico
  Future<void> init(String userId, {String? email, String? displayName, String? photoUrl}) async {
    debugPrint('[ProfileService] init chamado - userId: $userId, email: $email, displayName: $displayName');
    debugPrint('[ProfileService] Perfil atual em memória - id: ${_profile.id}, email: ${_profile.email}, displayName: ${_profile.displayName}');
    
    // Se já está inicializado para este usuário E o perfil já tem dados válidos,
    // não precisa recarregar (evita sobrescrever dados em memória)
    if (_currentUserId == userId && _profile.id == userId && _profile.email.isNotEmpty && _profile.displayName != null) {
      debugPrint('[ProfileService] Já inicializado com dados válidos, retornando');
      return;
    }

    // Preserva dados em memória se já existirem (de setProfileAfterRegistration)
    final preservedProfile = _profile.id == userId && _profile.email.isNotEmpty ? _profile : null;
    debugPrint('[ProfileService] Perfil preservado: ${preservedProfile != null}');

    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _profileRepository.getProfile(userId);

    switch (result) {
      case Success<UserProfile>(:final data):
        debugPrint('[ProfileService] getProfile retornou - email: ${data.email}, displayName: ${data.displayName}');
        if (data.email.isNotEmpty && data.displayName != null && data.displayName!.isNotEmpty) {
          // Perfil encontrado no Supabase com dados completos: usa ele
          debugPrint('[ProfileService] Usando perfil do Supabase');
          _profile = data;
        } else {
          // Perfil vazio ou incompleto no Supabase.
          // Se temos dados preservados em memória, usa eles. Senão, cria novo.
          if (preservedProfile != null) {
            debugPrint('[ProfileService] Usando perfil preservado em memória');
            _profile = preservedProfile;
          } else {
            debugPrint('[ProfileService] Criando novo perfil com parâmetros');
            _profile = UserProfile(
              id: userId,
              email: email ?? '',
              displayName: displayName,
              photoUrl: photoUrl,
              role: UserRole.student,
              martialArtType: null,
            );
          }
          
          // Tenta salvar no Supabase se ainda não foi salvo
          if (_profile.email.isNotEmpty) {
            debugPrint('[ProfileService] Salvando perfil no Supabase');
            await _profileRepository.saveProfile(_profile);
          }
        }

        debugPrint('[ProfileService] Perfil final - displayName: ${_profile.displayName}, martialArtType: ${_profile.martialArtType}');
        _isLoading = false;
        _error = null;
      case Failure<UserProfile>(:final message):
        debugPrint('[ProfileService] Erro ao buscar perfil: $message');
        // Se falhar ao buscar do Supabase, mantém o perfil em memória se existir
        if (preservedProfile != null) {
          debugPrint('[ProfileService] Mantendo perfil preservado após erro');
          _profile = preservedProfile;
          _error = null;
        } else if (_profile.id.isEmpty || _profile.email.isEmpty) {
          _error = message;
        }
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

