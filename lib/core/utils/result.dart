/// Result pattern para tratamento de erros sem exceptions
sealed class Result<T> {
  const Result();

  /// Cria um resultado de sucesso
  static Result<T> success<T>(T data) => Success<T>(data);

  /// Cria um resultado de falha
  static Result<T> failure<T>(Failure failure) => Failure<T>(
        message: failure.message,
        code: failure.code,
      );

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Fold para processar sucesso ou falha
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Failure<T>() => onFailure(this as Failure<T>),
    };
  }

  /// Mapeia o valor de sucesso
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(:final data) => Success(mapper(data)),
      Failure<T>(:final message, :final code) => Failure(
          message: message,
          code: code,
        ),
    };
  }
}

/// Resultado de sucesso
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Resultado de falha
final class Failure<T> extends Result<T> {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}
