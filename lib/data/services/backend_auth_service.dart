import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

class BackendAuthLoginResult {
  const BackendAuthLoginResult({
    required this.user,
    required this.token,
  });

  final AppUser user;
  final String token;
}

class BackendAuthService {
  const BackendAuthService({
    required BackendApiClient apiClient,
  }) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<Result<BackendAuthLoginResult>> login({
    required String email,
    required String password,
  }) async {
    final response = await _postAuth(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    if (!response.isSuccess || response.data is! Map<String, dynamic>) {
      return Result.failure(
        Failure(
          message: _extractMessage(response) ?? 'Falha ao fazer login',
          code: 'backend_auth_login_failed',
        ),
      );
    }

    final payload = response.data as Map<String, dynamic>;
    final userMap = payload['user'];
    final token = (payload['token'] as String? ?? '').trim();

    if (userMap is! Map<String, dynamic> || token.isEmpty) {
      return Result.failure(
        const Failure(
          message: 'Resposta de autenticação inválida',
          code: 'backend_auth_invalid_response',
        ),
      );
    }

    return Result.success(
      BackendAuthLoginResult(
        user: _mapUser(userMap),
        token: token,
      ),
    );
  }

  Future<Result<BackendAuthLoginResult>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final username = _buildUsername(normalizedEmail, displayName);

    final response = await _postAuth(
      '/auth/register',
      body: {
        'username': username,
        'email': normalizedEmail,
        'password': password,
      },
    );

    if (!response.isSuccess || response.data is! Map<String, dynamic>) {
      return Result.failure(
        Failure(
          message: _extractMessage(response) ?? 'Falha ao criar conta',
          code: 'backend_auth_register_failed',
        ),
      );
    }

    final payload = response.data as Map<String, dynamic>;
    final userMap = payload['user'];
    final token = (payload['token'] as String? ?? '').trim();
    if (userMap is! Map<String, dynamic> || token.isEmpty) {
      return Result.failure(
        const Failure(
          message: 'Resposta de cadastro inválida',
          code: 'backend_auth_invalid_response',
        ),
      );
    }

    return Result.success(
      BackendAuthLoginResult(
        user: _mapUser(userMap).copyWith(
          displayName: displayName?.trim().isNotEmpty == true
              ? displayName!.trim()
              : null,
        ),
        token: token,
      ),
    );
  }

  Future<Result<void>> forgotPassword(String email) async {
    final response = await _postAuth(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );

    if (!response.isSuccess) {
      return Result.failure(
        Failure(
          message:
              _extractMessage(response) ?? 'Não foi possível enviar o email',
          code: 'backend_forgot_password_failed',
        ),
      );
    }

    return Result.success(null);
  }

  Future<Result<void>> logout() async {
    final response = await _postAuth('/auth/logout');
    if (!response.isSuccess && response.statusCode != 401) {
      return Result.failure(
        Failure(
          message: _extractMessage(response) ?? 'Não foi possível sair da conta',
          code: 'backend_logout_failed',
        ),
      );
    }
    return Result.success(null);
  }

  Future<BackendApiResponse> _postAuth(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _apiClient.post(path, body: body);
    if (response.statusCode != 404) {
      return response;
    }

    if (!path.startsWith('/auth/')) {
      return response;
    }

    final v1Path = '/v1$path';
    return _apiClient.post(v1Path, body: body);
  }

  Future<Result<void>> updateProfile({
    String? displayName,
    UserRole? role,
    MartialArtType? martialArtType,
  }) async {
    final payload = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      payload['display_name'] = displayName.trim();
    }
    if (role != null) {
      payload['role'] = role.name;
    }
    if (martialArtType != null) {
      payload['martial_art_type'] = martialArtType.name;
    }

    if (payload.isEmpty) {
      return Result.success(null);
    }

    final response = await _apiClient.put('/v1/me', body: payload);
    if (!response.isSuccess) {
      return Result.failure(
        Failure(
          message:
              _extractMessage(response) ?? 'Não foi possível atualizar o perfil',
          code: 'backend_profile_update_failed',
        ),
      );
    }

    return Result.success(null);
  }

  AppUser _mapUser(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? map['username'] as String?,
      photoUrl: map['photo_url'] as String?,
      emailVerified: true,
    );
  }

  String _buildUsername(String email, String? displayName) {
    String source = displayName?.trim().toLowerCase() ?? '';
    if (source.isEmpty) {
      source = email.split('@').first.toLowerCase();
    }

    final normalized =
        source.replaceAll(RegExp(r'[^a-z0-9_]'), '_').replaceAll('__', '_');
    final base = normalized.isEmpty ? 'user' : normalized;
    final minPadded = base.length >= 3 ? base : '${base}123';
    return minPadded.length <= 50 ? minPadded : minPadded.substring(0, 50);
  }

  String? _extractMessage(BackendApiResponse response) {
    if (response.statusCode == -1) {
      return 'Nao foi possivel conectar ao backend. Verifique se a API esta rodando e a BACKEND_API_URL esta correta.';
    }

    if (response.statusCode == 404) {
      return 'Endpoint de autenticacao nao encontrado. Verifique se a API expoe /auth/* ou /v1/auth/*.';
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return response.rawBody?.trim().isNotEmpty == true ? response.rawBody : null;
  }
}

