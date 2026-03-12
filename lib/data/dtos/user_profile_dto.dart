import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// DTO genérico para serializar/deserializar `UserProfile`.
///
/// Mantém a estrutura de `Map<String, dynamic>` usada hoje em
/// `UserProfile.toMap` / `UserProfile.fromMap`, mas isola essa
/// representação na camada de dados.
class UserProfileDto {
  const UserProfileDto(this.data);

  /// Dados brutos (ex.: para Firestore, cache local, etc.)
  final Map<String, dynamic> data;

  /// Cria um DTO a partir do modelo de domínio.
  factory UserProfileDto.fromDomain(UserProfile profile) {
    return UserProfileDto(profile.toMap());
  }

  /// Converte o DTO de volta para o modelo de domínio.
  UserProfile toDomain() {
    return UserProfile.fromMap(data);
  }

  /// Atalho para serializar o DTO (por exemplo, para JSON).
  Map<String, dynamic> toJson() => data;

  /// Cria um DTO a partir de um JSON/Map serializado.
  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(json);
  }
}

