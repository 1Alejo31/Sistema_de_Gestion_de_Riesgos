import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_failure.dart';
import '../models/account_form_validators.dart';
import '../models/auth_identity.dart';
import '../models/auth_session.dart';
import '../services/auth_api_client.dart';

enum AuthStatus { signedOut, signingIn, authenticated, signingOut }

class AuthController extends ChangeNotifier {
  AuthController(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AuthApiClient _api;
  final DateTime Function() _now;
  static const sessionLifetime = Duration(minutes: 60);
  DateTime? _sessionDeadline;
  AuthSession? _session;
  AuthIdentity? _identity;
  AuthStatus _status = AuthStatus.signedOut;
  ApiFailure? _failure;
  String? _notice;
  Future<bool>? _loginFuture;
  Future<AuthSession>? _refreshFuture;
  Future<void>? _logoutFuture;
  Timer? _expiryTimer;
  Timer? _deadlineTimer;
  int _generation = 0;
  bool _disposed = false;
  bool _passwordChangeRequired = false;
  bool get passwordChangeRequired => _passwordChangeRequired;

  AuthStatus get status => _status;
  AuthIdentity? get identity => _identity;
  ApiFailure? get failure => _failure;
  String? get notice => _notice;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated &&
      _identity != null &&
      _session != null;
  bool get isBusy =>
      _status == AuthStatus.signingIn || _status == AuthStatus.signingOut;

  Future<bool> login(String email, String password) {
    if (_disposed || _logoutFuture != null || isAuthenticated) {
      return Future.value(false);
    }
    if (_loginFuture != null) return _loginFuture!;
    final future = _performLogin(email, password);
    _loginFuture = future;
    return future;
  }

  Future<bool> _performLogin(String email, String password) async {
    final generation = ++_generation;
    _sessionDeadline = _now().toUtc().add(sessionLifetime);
    _status = AuthStatus.signingIn;
    _failure = null;
    _notice = null;
    _notify();
    AuthSession? issued;
    try {
      issued = await _api.login(email.trim(), password);
      if (!_current(generation)) {
        await _revokeQuietly(issued);
        return false;
      }
      _session = issued;
      _passwordChangeRequired = issued.passwordChangeRequired;
      final identity = await _api.me(issued.accessToken);
      if (!_current(generation)) return false;
      if (identity.status != 'ACTIVE' || _deadlineReached) {
        throw const ApiFailure(ApiFailureKind.unauthorized);
      }
      _identity = identity;
      _passwordChangeRequired =
          _passwordChangeRequired || identity.passwordChangeRequired;
      _status = AuthStatus.authenticated;
      _deadlineTimer = Timer(
        _sessionDeadline!.difference(_now().toUtc()),
        () => unawaited(_endSession(expired: true)),
      );
      _scheduleRefresh();
      _notify();
      return true;
    } catch (error) {
      if (_current(generation)) {
        if (issued != null) await _revokeQuietly(issued);
        if (_current(generation)) _clear(failure: _safeFailure(error));
      }
      return false;
    } finally {
      _loginFuture = null;
    }
  }

  /// Entry point for other API services. It obtains the CURRENT token just
  /// before sending; consumers must not cache tokens or create their own retry.
  /// Mutations are never replayed automatically.
  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? organizationId,
    String? idempotencyKey,
    bool useServerErrorMessage = false,
  }) async {
    if (!isAuthenticated) throw const ApiFailure(ApiFailureKind.unauthorized);
    if (_passwordChangeRequired ||
        path.startsWith('/api/v1/auth/') ||
        path.startsWith('/api/v1/bootstrap')) {
      throw const ApiFailure(ApiFailureKind.validation);
    }
    return _protected(
      method,
      path,
      body: body,
      organizationId: organizationId,
      idempotencyKey: idempotencyKey,
      useServerErrorMessage: useServerErrorMessage,
    );
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!isAuthenticated) throw const ApiFailure(ApiFailureKind.unauthorized);
    if (currentPassword.isEmpty ||
        currentPassword == newPassword ||
        AccountFormValidators.password(newPassword) != null) {
      throw const ApiFailure(ApiFailureKind.validation);
    }
    final generation = _generation;
    final response = await _protected(
      'PATCH',
      '/api/v1/auth/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      useServerErrorMessage: true,
      endSessionOnUnauthorized: false,
    );
    _api.expectStatus(response, 204);
    if (response.bodyBytes.isNotEmpty) throw _api.unexpected(response);
    if (_current(generation)) {
      _clear(
        notice:
            'Contraseña actualizada correctamente. Inicia sesión con tu nueva contraseña.',
      );
    }
  }

  Future<void> verifySession() async {
    if (!isAuthenticated) return;
    final generation = _generation;
    try {
      final response = await _protected('GET', '/api/v1/auth/me');
      _api.expectStatus(response, 200);
      final identity = AuthIdentity.fromJson(_api.data(response));
      if (!_current(generation) || !isAuthenticated) return;
      if (identity.status != 'ACTIVE') {
        throw const ApiFailure(ApiFailureKind.unauthorized);
      }
      _identity = identity;
      _passwordChangeRequired =
          _passwordChangeRequired || identity.passwordChangeRequired;
      _notify();
    } catch (error) {
      if (_current(generation)) _clear(failure: _safeFailure(error));
    }
  }

  Future<http.Response> _protected(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? organizationId,
    String? idempotencyKey,
    bool useServerErrorMessage = false,
    bool endSessionOnUnauthorized = true,
  }) async {
    final generation = _generation;
    final session = await _validSession();
    _ensureLifetime();
    if (!_current(generation) || !isAuthenticated) {
      throw const ApiFailure(ApiFailureKind.unauthorized);
    }
    try {
      final response = await _api.send(
        method,
        path,
        body: body,
        organizationId: organizationId,
        accessToken: session.accessToken,
        idempotencyKey: idempotencyKey,
        useServerErrorMessage: useServerErrorMessage,
      );
      _ensureLifetime();
      if (!_current(generation) || !isAuthenticated) {
        throw const ApiFailure(ApiFailureKind.unauthorized);
      }
      return response;
    } on ApiFailure catch (error) {
      if (endSessionOnUnauthorized &&
          error.kind == ApiFailureKind.unauthorized &&
          _current(generation)) {
        // A late 401 for a token rotated by an overlapping request must not
        // invalidate the new session. The failed operation is not replayed.
        if (identical(_session, session)) {
          _clear(
            failure: error,
            notice: 'La sesión dejó de ser válida. Inicia sesión nuevamente.',
          );
        }
      }
      rethrow;
    }
  }

  Future<AuthSession> _validSession() async {
    _ensureLifetime();
    if (_refreshFuture != null) return _refreshFuture!;
    final session = _session;
    if (session == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    if (!_now().toUtc().isBefore(session.accessExpiresAt)) return _refresh();
    return session;
  }

  void _ensureLifetime() {
    if (_deadlineReached) {
      unawaited(_endSession(expired: true));
      throw const ApiFailure(ApiFailureKind.unauthorized);
    }
  }

  Future<AuthSession> _refresh() {
    if (_deadlineReached) {
      unawaited(_endSession(expired: true));
      return Future.error(const ApiFailure(ApiFailureKind.unauthorized));
    }
    if (_refreshFuture != null) return _refreshFuture!;
    final session = _session;
    if (session == null || !isAuthenticated) {
      return Future.error(const ApiFailure(ApiFailureKind.unauthorized));
    }
    _expiryTimer?.cancel();
    final future = _performRefresh(session, _generation);
    _refreshFuture = future;
    return future;
  }

  Future<AuthSession> _performRefresh(
    AuthSession previous,
    int generation,
  ) async {
    try {
      final next = await _api.refresh(previous.refreshToken);
      if (_current(generation) && _deadlineReached) {
        _clear(
          notice: 'La sesión alcanzó los 60 minutos. Inicia sesión nuevamente.',
        );
        await _revokeQuietly(next);
        throw const ApiFailure(ApiFailureKind.unauthorized);
      }
      if (_current(generation) && isAuthenticated) {
        _session = next;
        _scheduleRefresh();
      }
      return next;
    } catch (error) {
      final failure = _safeFailure(error);
      if (_current(generation)) {
        _clear(
          failure: failure,
          notice: 'No se pudo renovar la sesión. Inicia sesión nuevamente.',
        );
      }
      throw failure;
    } finally {
      _refreshFuture = null;
    }
  }

  void _scheduleRefresh() {
    _expiryTimer?.cancel();
    final delay = _session!.accessExpiresAt.difference(_now().toUtc());
    _expiryTimer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      try {
        await _refresh();
      } on ApiFailure {
        // State and safe user feedback are already updated by _performRefresh.
      }
    });
  }

  bool get _deadlineReached =>
      _sessionDeadline != null && !_now().toUtc().isBefore(_sessionDeadline!);

  Future<void> logout() => _endSession();

  Future<void> _endSession({bool expired = false}) {
    if (_disposed) return Future.value();
    if (_logoutFuture != null) return _logoutFuture!;
    final future = _performLogout(expired: expired).whenComplete(() {
      _logoutFuture = null;
    });
    _logoutFuture = future;
    return future;
  }

  Future<void> _performLogout({required bool expired}) async {
    final refreshing = _refreshFuture;
    final loggingIn = _loginFuture;
    var session = _session;
    final generation = ++_generation;
    _status = AuthStatus.signingOut;
    _identity = null;
    _expiryTimer?.cancel();
    _deadlineTimer?.cancel();
    _failure = null;
    _notify();
    ApiFailure? failure;
    try {
      if (loggingIn != null) await loggingIn;
      if (refreshing != null) {
        session = await refreshing;
      } else if (session != null &&
          !_now().toUtc().isBefore(session.accessExpiresAt)) {
        // Revocation needs a valid access token, even after idle expiration.
        session = await _api.refresh(session.refreshToken);
      }
      if (session != null) await _api.logout(session.accessToken);
    } catch (error) {
      failure = _safeFailure(error);
    } finally {
      if (_current(generation)) {
        _clear(
          failure: failure,
          notice: failure == null
              ? (expired
                    ? 'La sesión alcanzó los 60 minutos. Inicia sesión nuevamente.'
                    : 'Sesión cerrada.')
              : 'La sesión local se cerró, pero no pudimos confirmar la revocación en el servidor.',
        );
      }
    }
  }

  Future<void> _revokeQuietly(AuthSession session) async {
    try {
      await _api.logout(session.accessToken);
    } catch (_) {
      // No credentials or raw error are retained or logged.
    }
  }

  ApiFailure _safeFailure(Object error) =>
      error is ApiFailure ? error : const ApiFailure(ApiFailureKind.unexpected);

  bool _current(int generation) => !_disposed && generation == _generation;

  void _clear({ApiFailure? failure, String? notice}) {
    ++_generation;
    _expiryTimer?.cancel();
    _deadlineTimer?.cancel();
    _passwordChangeRequired = false;
    _sessionDeadline = null;
    _session = null;
    _identity = null;
    _status = AuthStatus.signedOut;
    _failure = failure;
    _notice = notice;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _expiryTimer?.cancel();
    _deadlineTimer?.cancel();
    _passwordChangeRequired = false;
    _sessionDeadline = null;
    _session = null;
    _identity = null;
    _api.close();
    super.dispose();
  }
}
