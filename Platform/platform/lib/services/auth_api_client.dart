import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_failure.dart';
import '../models/auth_identity.dart';
import '../models/auth_session.dart';

class AuthApiClient {
  AuthApiClient(
    this._config,
    this._client, {
    this.timeout = const Duration(seconds: 20),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiConfig? _config;
  final http.Client _client;
  final Duration timeout;
  final DateTime Function() _now;

  Future<AuthSession> login(String email, String password) async {
    final startedAt = _now();
    final response = await send(
      'POST',
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
      useServerErrorMessage: true,
    );
    return _session(response, 201, startedAt);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final startedAt = _now();
    final response = await send(
      'POST',
      '/api/v1/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return _session(response, 200, startedAt);
  }

  Future<AuthIdentity> me(String accessToken) async {
    final response = await send(
      'GET',
      '/api/v1/auth/me',
      accessToken: accessToken,
    );
    try {
      expectStatus(response, 200);
      return AuthIdentity.fromJson(data(response));
    } on FormatException {
      throw unexpected(response);
    }
  }

  Future<void> logout(String accessToken) async {
    final response = await send(
      'POST',
      '/api/v1/auth/logout',
      accessToken: accessToken,
    );
    expectStatus(response, 204);
    if (response.bodyBytes.isNotEmpty) throw unexpected(response);
  }

  AuthSession _session(
    http.Response response,
    int expectedStatus,
    DateTime startedAt,
  ) {
    try {
      expectStatus(response, expectedStatus);
      return AuthSession.fromJson(data(response), startedAt);
    } on FormatException {
      throw unexpected(response);
    }
  }

  /// Only configured API paths are accepted, so Bearer cannot leak to a URL
  /// supplied by a consumer. Redirects and automatic retries are disabled.
  Future<http.Response> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
    String? organizationId,
    String? idempotencyKey,
    bool useServerErrorMessage = false,
  }) async {
    final config = _config;
    if (config == null) throw const ApiFailure(ApiFailureKind.configuration);
    final uri = config.endpoint(path);
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (organizationId != null) {
      if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(organizationId)) {
        throw const ApiFailure(ApiFailureKind.validation);
      }
      request.headers['X-Organization-Id'] = organizationId;
    }
    if (idempotencyKey != null) {
      if (!RegExp(r'^[A-Za-z0-9._:-]{8,128}$').hasMatch(idempotencyKey)) {
        throw const ApiFailure(ApiFailureKind.validation);
      }
      request.headers['Idempotency-Key'] = idempotencyKey;
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final response = await (() async {
        final stream = await _client.send(request);
        return http.Response.fromStream(stream);
      })().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _failure(response, useServerErrorMessage: useServerErrorMessage);
      }
      return response;
    } on TimeoutException {
      throw const ApiFailure(ApiFailureKind.network);
    } on http.ClientException {
      throw const ApiFailure(ApiFailureKind.network);
    }
  }

  void expectStatus(http.Response response, int expected) {
    if (response.statusCode != expected) throw unexpected(response);
  }

  Map<String, dynamic> data(http.Response response) {
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (contentType != 'application/json') throw unexpected(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw unexpected(response);
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  ApiFailure unexpected(http.Response response) => ApiFailure(
    ApiFailureKind.unexpected,
    correlationId: _correlation(response),
  );

  ApiFailure _failure(
    http.Response response, {
    bool useServerErrorMessage = false,
  }) {
    final kind = switch (response.statusCode) {
      400 || 413 || 422 => ApiFailureKind.validation,
      401 => ApiFailureKind.unauthorized,
      403 => ApiFailureKind.forbidden,
      429 => ApiFailureKind.rateLimit,
      _ => ApiFailureKind.unexpected,
    };
    return ApiFailure(
      kind,
      statusCode: response.statusCode,
      correlationId: _correlation(response),
      serverMessage: useServerErrorMessage ? _errorMessage(response) : null,
    );
  }

  String? _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        final message = decoded['error']['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } on FormatException {
      // Missing or malformed messages retain the existing fallback.
    }
    return null;
  }

  String? _correlation(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        final id = ApiFailure.safeCorrelationId(
          decoded['error']['correlationId'],
        );
        if (id != null) return id;
      }
    } on FormatException {
      // An HTML/proxy response is still reported without its contents.
    }
    return ApiFailure.safeCorrelationId(response.headers['x-correlation-id']);
  }

  void close() => _client.close();
}
