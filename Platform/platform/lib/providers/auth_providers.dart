import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../controllers/auth_controller.dart';
import '../models/api_failure.dart';
import '../models/auth_identity.dart';
import '../services/auth_api_client.dart';

/// One controller per application scope. Tokens stay private to the controller.
final apiConfigProvider = Provider<ApiConfig?>((ref) {
  ApiConfig? config;
  try {
    config = ApiConfig.fromEnvironment();
  } on FormatException {
    // Keep public pages available; login reports a safe configuration error.
  }
  return config;
}, dependencies: []);

// The controller owns and closes its HTTP client. Tests can inject transport
// while exercising the real startup/configuration/provider path.
final authHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
  dependencies: [],
);

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(
    AuthApiClient(
      ref.watch(apiConfigProvider),
      ref.watch(authHttpClientProvider),
    ),
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [apiConfigProvider, authHttpClientProvider]);

/// Only public UI state belongs in Riverpod: never tokens or passwords.
class AuthState {
  const AuthState({
    required this.status,
    required this.identity,
    required this.failure,
    required this.notice,
    this.passwordChangeRequired = false,
  });

  factory AuthState.fromController(AuthController controller) => AuthState(
    passwordChangeRequired: controller.passwordChangeRequired,
    status: controller.status,
    identity: controller.identity,
    failure: controller.failure,
    notice: controller.notice,
  );

  final bool passwordChangeRequired;
  final AuthStatus status;
  final AuthIdentity? identity;
  final ApiFailure? failure;
  final String? notice;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && identity != null;
  bool get isBusy =>
      status == AuthStatus.signingIn || status == AuthStatus.signingOut;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
  dependencies: [authControllerProvider],
);

/// Bridges the tested HTTP/session coordinator to immutable Riverpod snapshots.
class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final controller = ref.watch(authControllerProvider);
    void changed() => state = AuthState.fromController(controller);
    controller.addListener(changed);
    ref.onDispose(() => controller.removeListener(changed));
    return AuthState.fromController(controller);
  }
}
