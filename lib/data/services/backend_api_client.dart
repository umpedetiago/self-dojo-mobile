import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:self_dojo_mobile/core/config/backend_api_config.dart';

typedef BackendApiTokenProvider = String? Function();
typedef BackendApiUnauthorizedHandler = Future<void> Function();

class BackendApiResponse {
  const BackendApiResponse({
    required this.statusCode,
    this.data,
    this.rawBody,
  });

  final int statusCode;
  final dynamic data;
  final String? rawBody;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class BackendApiClient {
  const BackendApiClient({
    this.tokenProvider,
    this.onUnauthorized,
  });

  final BackendApiTokenProvider? tokenProvider;
  final BackendApiUnauthorizedHandler? onUnauthorized;

  bool get isConfigured => BackendApiConfig.isEnabled;
  bool get hasAuthToken => _resolveToken().isNotEmpty;
  bool get canCallProtectedApi => isConfigured && hasAuthToken;

  Future<BackendApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _request('GET', path, queryParameters: queryParameters);
  }

  Future<BackendApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<BackendApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<BackendApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<BackendApiResponse> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _request('DELETE', path, queryParameters: queryParameters);
  }

  Future<BackendApiResponse> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final base = BackendApiConfig.baseUrl.trim();
    if (base.isEmpty) {
      return const BackendApiResponse(statusCode: 0, rawBody: 'Backend API URL not configured');
    }

    final uri = Uri.parse('$base$path').replace(queryParameters: queryParameters);
    final client = HttpClient();

    try {
      if (kDebugMode) {
        debugPrint('[BackendApiClient] REQUEST: $method $uri');
        if (body != null) {
          debugPrint('[BackendApiClient] Request body: ${jsonEncode(body)}');
        }
      }

      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final token = _resolveToken();
      if (token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (kDebugMode) {
        debugPrint(
          '[BackendApiClient] RESPONSE: $method $uri '
          'status=${response.statusCode}',
        );
        if (responseBody.isNotEmpty) {
          debugPrint('[BackendApiClient] Response body: $responseBody');
        }
      }

      dynamic decoded;
      if (responseBody.isNotEmpty) {
        try {
          decoded = jsonDecode(responseBody);
        } catch (_) {
          decoded = null;
        }
      }

      final result = BackendApiResponse(
        statusCode: response.statusCode,
        data: decoded,
        rawBody: responseBody,
      );

      if (result.statusCode == HttpStatus.unauthorized &&
          onUnauthorized != null) {
        await onUnauthorized!.call();
      }

      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[BackendApiClient] ERROR: $method $path - $e');
        debugPrint('[BackendApiClient] StackTrace: $stackTrace');
      }
      return BackendApiResponse(statusCode: -1, rawBody: e.toString());
    } finally {
      client.close();
    }
  }

  String _resolveToken() {
    final providedToken = tokenProvider?.call()?.trim() ?? '';
    if (providedToken.isNotEmpty) {
      return providedToken;
    }
    return BackendApiConfig.apiToken.trim();
  }
}

