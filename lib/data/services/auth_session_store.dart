import 'dart:convert';
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:self_dojo_mobile/domain/models/user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AppUser user;
}

class AuthSessionStore {
  AuthSessionStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth.token';
  static const String _userKey = 'auth.user';

  final FlutterSecureStorage _secureStorage;
  final StreamController<AuthSession?> _sessionController =
      StreamController<AuthSession?>.broadcast();

  String? _cachedToken;
  AppUser? _cachedUser;

  String? get token => _cachedToken;
  AppUser? get user => _cachedUser;
  bool get hasSession => (_cachedToken ?? '').trim().isNotEmpty;
  Stream<AuthSession?> get sessionChanges => _sessionController.stream;

  Future<void> initialize() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final userRaw = await _secureStorage.read(key: _userKey);

    _cachedToken = token?.trim().isNotEmpty == true ? token!.trim() : null;
    _cachedUser = _decodeUser(userRaw);
    _sessionController.add(currentSession);
  }

  Future<void> saveSession(AuthSession session) async {
    _cachedToken = session.token.trim();
    _cachedUser = session.user;

    await _secureStorage.write(key: _tokenKey, value: _cachedToken);
    await _secureStorage.write(key: _userKey, value: _encodeUser(session.user));
    _sessionController.add(session);
  }

  Future<void> clear() async {
    _cachedToken = null;
    _cachedUser = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    _sessionController.add(null);
  }

  AuthSession? get currentSession {
    final token = _cachedToken?.trim() ?? '';
    if (token.isEmpty || _cachedUser == null) {
      return null;
    }
    return AuthSession(token: token, user: _cachedUser!);
  }

  String _encodeUser(AppUser user) {
    return jsonEncode({
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'emailVerified': user.emailVerified,
    });
  }

  AppUser? _decodeUser(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AppUser(
        id: decoded['id'] as String? ?? '',
        email: decoded['email'] as String? ?? '',
        displayName: decoded['displayName'] as String?,
        photoUrl: decoded['photoUrl'] as String?,
        emailVerified: decoded['emailVerified'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }
}

