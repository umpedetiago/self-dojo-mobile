import 'package:equatable/equatable.dart';

/// Domain Model do usuário
/// Representa o usuário dentro do app (independente da fonte de dados)
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  /// Usuário vazio para estados iniciais
  static const empty = AppUser(id: '', email: '');

  /// Verifica se o usuário está vazio
  bool get isEmpty => this == empty;
  bool get isNotEmpty => !isEmpty;

  /// Cria cópia com valores alterados
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, emailVerified];

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, displayName: $displayName)';
}

