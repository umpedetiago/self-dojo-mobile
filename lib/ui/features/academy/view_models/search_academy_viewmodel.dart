import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_search_result.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// ViewModel para busca de academias
class SearchAcademyViewModel extends ChangeNotifier {
  SearchAcademyViewModel({
    required AcademySearchRepository searchRepository,
    required String userId,
  })  : _searchRepository = searchRepository,
        _userId = userId {
    sendJoinRequest = Command1(_sendJoinRequest);
    cancelJoinRequest = Command1(_cancelJoinRequest);
  }

  final AcademySearchRepository _searchRepository;
  final String _userId;

  // State
  List<AcademySearchResult> _academies = [];
  List<AcademySearchResult> get academies => _academies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  MartialArtType? _filterModality;
  MartialArtType? get filterModality => _filterModality;

  // Cache de status de solicitação por academia
  final Map<String, MemberRequestStatus> _requestStatuses = {};

  // Commands
  late final Command1<void, SendJoinRequestParams> sendJoinRequest;
  late final Command1<void, String> cancelJoinRequest;

  /// Busca academias
  Future<void> search(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _hasSearched = true;
    _error = null;
    notifyListeners();

    final result = await _searchRepository.searchAcademies(
      query: query.isNotEmpty ? query : null,
      modalityType: _filterModality,
    );

    result.fold(
      onSuccess: (academies) {
        _academies = academies;
        _isLoading = false;
        // Carrega status de solicitação para cada academia
        _loadRequestStatuses();
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  /// Filtra por modalidade
  void filterByModality(MartialArtType? type) {
    _filterModality = type;
    if (_hasSearched) {
      search(_searchQuery);
    }
  }

  /// Limpa busca
  void clearSearch() {
    _searchQuery = '';
    _academies = [];
    _hasSearched = false;
    _error = null;
    notifyListeners();
  }

  /// Carrega status de solicitação para as academias
  Future<void> _loadRequestStatuses() async {
    for (final academy in _academies) {
      if (!_requestStatuses.containsKey(academy.id)) {
        final result = await _searchRepository.getRequestStatus(
          academyId: academy.id,
          oderId: _userId,
        );
        result.fold(
          onSuccess: (status) {
            _requestStatuses[academy.id] = status;
          },
          onFailure: (_) {},
        );
      }
    }
    notifyListeners();
  }

  /// Retorna status de solicitação para uma academia
  MemberRequestStatus getRequestStatus(String academyId) {
    return _requestStatuses[academyId] ?? MemberRequestStatus.none;
  }

  /// Envia solicitação de vínculo
  Future<Result<void>> _sendJoinRequest(SendJoinRequestParams params) async {
    final result = await _searchRepository.sendJoinRequest(
      academyId: params.academyId,
      oderId: _userId,
      modalities: params.modalities,
      message: params.message,
    );

    if (result.isSuccess) {
      _requestStatuses[params.academyId] = MemberRequestStatus.pending;
      notifyListeners();
    }

    return result;
  }

  /// Cancela solicitação
  Future<Result<void>> _cancelJoinRequest(String academyId) async {
    final result = await _searchRepository.cancelJoinRequest(
      academyId: academyId,
      oderId: _userId,
    );

    if (result.isSuccess) {
      _requestStatuses[academyId] = MemberRequestStatus.none;
      notifyListeners();
    }

    return result;
  }

  /// Atualiza status de uma academia específica
  Future<void> refreshRequestStatus(String academyId) async {
    final result = await _searchRepository.getRequestStatus(
      academyId: academyId,
      oderId: _userId,
    );
    result.fold(
      onSuccess: (status) {
        _requestStatuses[academyId] = status;
        notifyListeners();
      },
      onFailure: (_) {},
    );
  }
}

/// Parâmetros para enviar solicitação
class SendJoinRequestParams {
  const SendJoinRequestParams({
    required this.academyId,
    this.modalities,
    this.message,
  });

  final String academyId;
  final List<MartialArtType>? modalities;
  final String? message;
}

