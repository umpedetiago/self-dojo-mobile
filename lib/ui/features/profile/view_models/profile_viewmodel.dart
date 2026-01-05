import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// ViewModel do Perfil do Usuário
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required ProfileRepository profileRepository,
    required String userId,
    AppUser? authUser,
  })  : _profileRepository = profileRepository,
        _userId = userId,
        _authUser = authUser {
    updatePhoto = Command1(_updatePhoto);
    updateProfile = Command1(_updateProfile);
    _init();
  }

  final ProfileRepository _profileRepository;
  final String _userId;
  final AppUser? _authUser;
  StreamSubscription<UserProfile?>? _profileSubscription;

  // State
  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Commands
  late final Command1<String, File> updatePhoto;
  late final Command1<void, UserProfile> updateProfile;

  void _init() {
    // Escuta mudanças no perfil
    _profileSubscription = _profileRepository.watchProfile(_userId).listen(
      (profile) {
        if (profile != null) {
          _profile = profile;
          _isLoading = false;
          _error = null;
        } else {
          // Perfil não existe, criar um novo
          _createInitialProfile();
        }
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar perfil';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _createInitialProfile() async {
    final result = await _profileRepository.createProfile(
      userId: _userId,
      email: _authUser?.email ?? 'user@email.com',
      displayName: _authUser?.displayName,
    );

    result.fold(
      onSuccess: (profile) {
        _profile = profile;
        _isLoading = false;
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
      },
    );

    notifyListeners();
  }

  /// Atualiza a foto de perfil
  Future<Result<String>> _updatePhoto(File photo) async {
    final result = await _profileRepository.updateProfilePhoto(
      userId: _userId,
      photo: photo,
    );

    result.fold(
      onSuccess: (url) {
        _profile = _profile.copyWith(photoUrl: url);
      },
      onFailure: (_) {},
    );

    notifyListeners();
    return result;
  }

  /// Atualiza o perfil
  Future<Result<void>> _updateProfile(UserProfile newProfile) async {
    return _profileRepository.updateProfile(newProfile);
  }

  /// Registra uma aula (check-in)
  Future<Result<void>> registerClass() async {
    return _profileRepository.registerClass(_userId);
  }

  /// Muda a arte marcial
  Future<Result<void>> changeMartialArt(MartialArtType newType) async {
    final martialArt = MartialArtsConfig.getByType(newType);
    final newProfile = _profile.copyWith(
      martialArtType: newType,
      graduation: _profile.graduation?.copyWith(
        beltId: martialArt.initialBelt.id,
        degree: 0,
        classesAtCurrentBelt: 0,
      ),
    );

    return _profileRepository.updateProfile(newProfile);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}

