import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/ui/commands/command.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';

/// ViewModel para gerenciamento de solicitações de vínculo
class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel({
    required AcademySearchRepository searchRepository,
    required String academyId,
  })  : _searchRepository = searchRepository,
        _academyId = academyId {
    approveRequest = Command1(_approveRequest);
    rejectRequest = Command1(_rejectRequest);
    _loadRequests();
  }

  final AcademySearchRepository _searchRepository;
  final String _academyId;

  // State
  List<JoinRequest> _requests = [];
  List<JoinRequest> get requests => _requests;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Commands
  late final Command1<void, String> approveRequest;
  late final Command1<void, String> rejectRequest;

  /// Carrega solicitações pendentes
  Future<void> _loadRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _searchRepository.getPendingRequests(_academyId);

    result.fold(
      onSuccess: (requests) {
        _requests = requests;
        _isLoading = false;
      },
      onFailure: (failure) {
        _error = failure.message;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  /// Recarrega a lista
  Future<void> refresh() async {
    await _loadRequests();
  }

  /// Aprova solicitação
  Future<Result<void>> _approveRequest(String memberId) async {
    final result = await _searchRepository.approveRequest(memberId);

    if (result.isSuccess) {
      // Remove da lista local
      _requests = _requests.where((r) => r.memberId != memberId).toList();
      notifyListeners();
    }

    return result;
  }

  /// Rejeita solicitação
  Future<Result<void>> _rejectRequest(String memberId) async {
    final result = await _searchRepository.rejectRequest(memberId);

    if (result.isSuccess) {
      // Remove da lista local
      _requests = _requests.where((r) => r.memberId != memberId).toList();
      notifyListeners();
    }

    return result;
  }

  /// Retorna contagem de solicitações
  int get requestCount => _requests.length;
}

