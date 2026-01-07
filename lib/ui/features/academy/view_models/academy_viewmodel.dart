import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// ViewModel para gerenciamento da Academia
class AcademyViewModel extends ChangeNotifier {
  AcademyViewModel({
    required AcademyRepository academyRepository,
    required ProfileRepository profileRepository,
    required String userId,
  })  : _academyRepository = academyRepository,
        _profileRepository = profileRepository,
        _userId = userId {
    createAcademy = Command1(_createAcademy);
    updateAcademy = Command1(_updateAcademy);
    addModality = Command1(_addModality);
    removeModality = Command1(_removeModality);
    _init();
  }

  final AcademyRepository _academyRepository;
  final ProfileRepository _profileRepository;
  final String _userId;
  StreamSubscription<Academy?>? _academySubscription;

  // State
  Academy _academy = Academy.empty;
  Academy get academy => _academy;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _studentCount = 0;
  int get studentCount => _studentCount;

  // Commands
  late final Command1<Academy, CreateAcademyParams> createAcademy;
  late final Command1<void, Academy> updateAcademy;
  late final Command1<void, MartialArtType> addModality;
  late final Command1<void, MartialArtType> removeModality;

  /// Verifica se o usuário já tem uma academia
  bool get hasAcademy => _academy.isNotEmpty;

  /// Verifica se está no período de trial
  bool get isOnTrial => _academy.subscription?.isTrial ?? false;

  /// Dias restantes do trial
  int get trialDaysRemaining =>
      _academy.subscription?.trialDaysRemaining ?? 0;

  /// Verifica se pode adicionar mais alunos
  bool get canAddStudent => _academy.canAddStudent(_studentCount);

  /// Verifica se pode adicionar mais modalidades
  bool get canAddModality => _academy.canAddModality();

  void _init() async {
    // Primeiro tenta buscar academia existente do owner
    final result = await _academyRepository.getOwnerAcademy(_userId);

    result.fold(
      onSuccess: (academy) {
        if (academy != null) {
          _academy = academy;
          _watchAcademy(academy.id);
          _loadStudentCount(academy.id);
        }
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _watchAcademy(String academyId) {
    _academySubscription?.cancel();
    _academySubscription = _academyRepository.watchAcademy(academyId).listen(
      (academy) {
        if (academy != null) {
          _academy = academy;
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Erro ao monitorar academia';
        notifyListeners();
      },
    );
  }

  Future<void> _loadStudentCount(String academyId) async {
    final result = await _academyRepository.countStudents(academyId);
    result.fold(
      onSuccess: (count) {
        _studentCount = count;
        notifyListeners();
      },
      onFailure: (_) {},
    );
  }

  /// Cria uma nova academia
  Future<Result<Academy>> _createAcademy(CreateAcademyParams params) async {
    final result = await _academyRepository.createAcademy(
      ownerId: _userId,
      name: params.name,
      modalities: params.modalities,
      description: params.description,
      address: params.address,
      city: params.city,
      state: params.state,
      phone: params.phone,
      email: params.email,
    );

    await result.fold(
      onSuccess: (academy) async {
        _academy = academy;
        _watchAcademy(academy.id);

        // Busca o perfil atual
        final profileResult = await _profileRepository.getProfile(_userId);
        await profileResult.fold(
          onSuccess: (currentProfile) async {
            // Atualiza o perfil do usuário para owner mantendo outros dados
            final updatedProfile = currentProfile.copyWith(
              role: UserRole.owner,
              academyId: academy.id,
              academyStatus: AcademyStatus.approved,
            );
            await _profileRepository.updateProfile(updatedProfile);
          },
          onFailure: (_) async {
            // Se não encontrou perfil, cria um novo
            await _profileRepository.saveProfile(
              UserProfile(
                id: _userId,
                email: params.email ?? '',
                role: UserRole.owner,
                academyId: academy.id,
                academyStatus: AcademyStatus.approved,
              ),
            );
          },
        );
      },
      onFailure: (_) {},
    );

    notifyListeners();
    return result;
  }

  /// Atualiza a academia
  Future<Result<void>> _updateAcademy(Academy academy) async {
    final result = await _academyRepository.updateAcademy(academy);
    result.fold(
      onSuccess: (_) {
        _academy = academy;
      },
      onFailure: (_) {},
    );
    notifyListeners();
    return result;
  }

  /// Adiciona uma modalidade
  Future<Result<void>> _addModality(MartialArtType type) async {
    return _academyRepository.addModality(_academy.id, type);
  }

  /// Remove uma modalidade
  Future<Result<void>> _removeModality(MartialArtType type) async {
    return _academyRepository.removeModality(_academy.id, type);
  }

  /// Define mestre de uma modalidade
  Future<Result<void>> setModalityMaster(
    MartialArtType type,
    String? masterId,
  ) async {
    return _academyRepository.setModalityMaster(_academy.id, type, masterId);
  }

  /// Atualiza configuração de graduação
  Future<Result<void>> updateGraduationConfig(
    MartialArtType type,
    GraduationConfig config,
  ) async {
    return _academyRepository.updateGraduationConfig(
      _academy.id,
      type,
      config,
    );
  }

  @override
  void dispose() {
    _academySubscription?.cancel();
    super.dispose();
  }
}

/// Parâmetros para criar academia
class CreateAcademyParams {
  const CreateAcademyParams({
    required this.name,
    required this.modalities,
    this.description,
    this.address,
    this.city,
    this.state,
    this.phone,
    this.email,
  });

  final String name;
  final List<MartialArtType> modalities;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? phone;
  final String? email;
}

