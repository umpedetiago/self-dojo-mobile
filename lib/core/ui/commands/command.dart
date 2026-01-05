import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';

/// Command sem parâmetros
/// Encapsula uma ação assíncrona com estados de loading/error
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result != null;
  bool get hasError => _result?.isFailure ?? false;
  bool get hasData => _result?.isSuccess ?? false;

  T? get data => _result is Success<T> ? (_result as Success<T>).data : null;

  String? get errorMessage =>
      _result is Failure<T> ? (_result as Failure<T>).message : null;

  /// Executa a ação
  Future<Result<T>> execute() async {
    if (_running) {
      return Result.failure(const Failure(message: 'Already running'));
    }

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action();
    } catch (e) {
      _result = Result.failure(Failure(message: e.toString()));
    }

    _running = false;
    notifyListeners();

    return _result!;
  }

  /// Limpa o resultado
  void clear() {
    _result = null;
    notifyListeners();
  }
}

/// Command com 1 parâmetro
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result != null;
  bool get hasError => _result?.isFailure ?? false;
  bool get hasData => _result?.isSuccess ?? false;

  T? get data => _result is Success<T> ? (_result as Success<T>).data : null;

  String? get errorMessage =>
      _result is Failure<T> ? (_result as Failure<T>).message : null;

  /// Executa a ação com o argumento
  Future<Result<T>> execute(A argument) async {
    if (_running) {
      return Result.failure(const Failure(message: 'Already running'));
    }

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action(argument);
    } catch (e) {
      _result = Result.failure(Failure(message: e.toString()));
    }

    _running = false;
    notifyListeners();

    return _result!;
  }

  /// Limpa o resultado
  void clear() {
    _result = null;
    notifyListeners();
  }
}

/// Command com 2 parâmetros
class Command2<T, A, B> extends ChangeNotifier {
  Command2(this._action);

  final Future<Result<T>> Function(A, B) _action;

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result != null;
  bool get hasError => _result?.isFailure ?? false;
  bool get hasData => _result?.isSuccess ?? false;

  T? get data => _result is Success<T> ? (_result as Success<T>).data : null;

  String? get errorMessage =>
      _result is Failure<T> ? (_result as Failure<T>).message : null;

  /// Executa a ação com os argumentos
  Future<Result<T>> execute(A arg1, B arg2) async {
    if (_running) {
      return Result.failure(const Failure(message: 'Already running'));
    }

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action(arg1, arg2);
    } catch (e) {
      _result = Result.failure(Failure(message: e.toString()));
    }

    _running = false;
    notifyListeners();

    return _result!;
  }

  /// Limpa o resultado
  void clear() {
    _result = null;
    notifyListeners();
  }
}

