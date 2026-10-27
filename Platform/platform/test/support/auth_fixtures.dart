import 'dart:convert';
import 'package:flutter/widgets.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:landing_page/config/api_config.dart';
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/services/auth_api_client.dart';

http.Response jsonResponse(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response sessionResponse({
  int status = 201,
  int expiresIn = 3600,
  String suffix = 'one',
}) => jsonResponse({
  'data': {
    'accessToken': 'opaque-access-$suffix',
    'refreshToken': 'opaque-refresh-$suffix',
    'expiresIn': expiresIn,
    'session': {'id': 'session-$suffix', 'expiresAt': '2030-01-01T00:00:00Z'},
  },
}, status);

http.Response identityResponse() => jsonResponse({
  'data': {
    'id': 'identity-one',
    'email': 'persona@example.com',
    'status': 'ACTIVE',
    'roles': ['SUPER_ADMIN'],
    'scope': 'GLOBAL',
  },
}, 200);

http.Response errorResponse(
  int status, {
  String message = 'Internal details must not be shown',
}) => jsonResponse({
  'error': {
    'code': 'UNAUTHORIZED',
    'message': message,
    'correlationId': 'support-12345',
  },
}, status);

AuthController createAuth({
  Future<http.Response> Function(http.Request)? handler,
  DateTime Function()? now,
  Duration timeout = const Duration(seconds: 20),
}) => AuthController(
  AuthApiClient(
    ApiConfig('https://api.example.com'),
    MockClient(handler ?? defaultHandler),
    now: now,
    timeout: timeout,
  ),
  now: now,
);

Future<http.Response> defaultHandler(http.Request request) async =>
    switch (request.url.path) {
      '/api/v1/auth/login' => sessionResponse(),
      '/api/v1/auth/me' => identityResponse(),
      '/api/v1/auth/logout' => http.Response('', 204),
      '/api/v1/auth/refresh' => sessionResponse(status: 200, suffix: 'two'),
      _ => jsonResponse({'data': []}, 200),
    };

/// Owns the injected controller for widget tests, cancelling session timers
/// during tree disposal, before Flutter verifies pending-timer invariants.
class AuthTestHost extends StatefulWidget {
  const AuthTestHost({super.key, required this.auth, required this.child});
  final AuthController auth;
  final Widget child;
  @override
  State<AuthTestHost> createState() => _AuthTestHostState();
}

class _AuthTestHostState extends State<AuthTestHost> {
  @override
  Widget build(BuildContext context) => widget.child;
  @override
  void dispose() {
    widget.auth.dispose();
    super.dispose();
  }
}
