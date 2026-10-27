import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/config/api_config.dart';
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/services/auth_api_client.dart';

import 'support/auth_fixtures.dart';

void main() {
  test('logout without a session does not block a later login', () async {
    final auth = createAuth();
    addTearDown(auth.dispose);
    await auth.logout();
    expect(await auth.login('persona@example.com', 'password'), isTrue);
  });

  test('protected response arriving after the deadline is discarded', () async {
    var now = DateTime.utc(2026, 10, 1);
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final auth = createAuth(
      now: () => now,
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 7200);
        }
        if (request.url.path.endsWith('/roles')) {
          started.complete();
          return pending.future;
        }
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    now = now.add(const Duration(minutes: 59));
    final request = expectLater(
      auth.request('GET', '/api/v1/roles'),
      throwsA(isA<ApiFailure>()),
    );
    await started.future;
    now = now.add(const Duration(minutes: 1));
    pending.complete(jsonResponse({'data': []}, 200));
    await request;
    await auth.logout();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.notice, contains('60 minutos'));
  });

  test('refresh arriving after 60 minutes cannot restore access', () async {
    var now = DateTime.utc(2026, 10, 1);
    final pending = Completer<http.Response>();
    final refreshStarted = Completer<void>();
    final revocations = <String?>[];
    var serviceCalls = 0;
    final auth = createAuth(
      now: () => now,
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 900);
        }
        if (request.url.path.endsWith('/refresh')) {
          refreshStarted.complete();
          return pending.future;
        }
        if (request.url.path.endsWith('/logout')) {
          revocations.add(request.headers['Authorization']);
        }
        if (request.url.path.endsWith('/roles')) serviceCalls++;
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    now = now.add(const Duration(minutes: 59));
    final request = expectLater(
      auth.request('GET', '/api/v1/roles'),
      throwsA(isA<ApiFailure>()),
    );
    await refreshStarted.future;
    now = now.add(const Duration(minutes: 1));
    pending.complete(sessionResponse(status: 200, suffix: 'late'));
    await request;
    expect(auth.isAuthenticated, isFalse);
    expect(auth.identity, isNull);
    expect(serviceCalls, 0);
    expect(revocations, ['Bearer opaque-access-late']);
    expect(auth.notice, contains('60 minutos'));
  });

  test('rotation does not extend the 60 minute local deadline', () async {
    var now = DateTime.utc(2026, 10, 1);
    var refreshes = 0;
    var serviceCalls = 0;
    final auth = createAuth(
      now: () => now,
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 900);
        }
        if (request.url.path.endsWith('/refresh')) refreshes++;
        if (request.url.path.endsWith('/roles')) serviceCalls++;
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    now = now.add(const Duration(minutes: 59));
    // Rotate the expired access token one minute before the absolute deadline.
    await auth.request('GET', '/api/v1/roles');
    expect(refreshes, 1);
    now = DateTime.utc(2026, 10, 1, 1);
    await expectLater(
      auth.request('GET', '/api/v1/roles'),
      throwsA(isA<ApiFailure>()),
    );
    expect(auth.isAuthenticated, isFalse);
    await auth.logout();
    expect(serviceCalls, 1);
    // Logout revokes the still-valid rotated token without another refresh.
    expect(refreshes, 1);
    expect(auth.notice, contains('60 minutos'));
  });

  test(
    'late unauthorized response from a rotated token preserves current session',
    () async {
      var now = DateTime.utc(2026, 10, 1);
      final oldResponse = Completer<http.Response>();
      var roleCalls = 0;
      final auth = createAuth(
        now: () => now,
        handler: (request) async {
          if (request.url.path.endsWith('/login')) {
            return sessionResponse(expiresIn: 1);
          }
          if (request.url.path.endsWith('/roles') && ++roleCalls == 1) {
            return oldResponse.future;
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      final failedOldRequest = expectLater(
        auth.request('GET', '/api/v1/roles'),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(seconds: 1));
      await auth.request('GET', '/api/v1/permissions');
      oldResponse.complete(errorResponse(401));
      await failedOldRequest;
      expect(auth.isAuthenticated, isTrue);
      expect(auth.identity?.email, 'persona@example.com');
      expect(roleCalls, 1);
    },
  );

  test('expired logout renews once before revoking current session', () async {
    var now = DateTime.utc(2026, 10, 1);
    final requests = <http.Request>[];
    final auth = createAuth(
      now: () => now,
      handler: (request) async {
        requests.add(request);
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 1);
        }
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    now = now.add(const Duration(seconds: 1));
    await auth.logout();
    expect(requests.where((r) => r.url.path.endsWith('/refresh')).length, 1);
    expect(requests.last.url.path, '/api/v1/auth/logout');
    expect(requests.last.headers['Authorization'], 'Bearer opaque-access-two');
    expect(auth.isAuthenticated, isFalse);
  });

  test(
    'forbidden service action does not discard an otherwise valid session',
    () async {
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/organizations')) {
            return errorResponse(403);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      await expectLater(
        auth.request('GET', '/api/v1/organizations'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.forbidden,
          ),
        ),
      );
      expect(auth.isAuthenticated, isTrue);
    },
  );

  test('configuration confines requests to a safe configured origin', () {
    final development = ApiConfig(
      'http://api.example.com',
      allowDevelopmentHttp: true,
    );
    expect(
      development.endpoint('/api/v1/auth/login').toString(),
      'http://api.example.com/api/v1/auth/login',
    );
    for (final value in [
      '',
      'http://api.example.com',
      'https://u:p@example.com',
      'https://example.com?token=secret',
      'https://example.com/#secret',
      'https://example.com/path',
    ]) {
      expect(() => ApiConfig(value), throwsFormatException);
    }
    expect(() => ApiConfig('http://localhost:3000'), throwsFormatException);
    final local = ApiConfig('http://localhost:3000', allowLocalHttp: true);
    expect(
      local.endpoint('/api/v1/auth/login').toString(),
      'http://localhost:3000/api/v1/auth/login',
    );
    for (final path in [
      'https://other.example.com',
      '//other.example.com',
      '/api/v1/../../secret',
      '/api/v1/roles?token=secret',
    ]) {
      expect(() => local.endpoint(path), throwsFormatException);
    }
  });

  test(
    'login sends exact JSON, accepts 201 and obtains identity with opaque Bearer',
    () async {
      final requests = <http.Request>[];
      final auth = createAuth(
        handler: (request) async {
          requests.add(request);
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      expect(
        await auth.login(' persona@example.com ', 'password unchanged '),
        isTrue,
      );
      final login = requests.first;
      expect(login.method, 'POST');
      expect(login.url.toString(), 'https://api.example.com/api/v1/auth/login');
      expect(jsonDecode(login.body), {
        'email': 'persona@example.com',
        'password': 'password unchanged ',
      });
      expect(login.headers['Accept'], 'application/json');
      expect(login.headers['Content-Type'], startsWith('application/json'));
      expect(login.followRedirects, isFalse);
      expect(login.headers.containsKey('Authorization'), isFalse);
      expect(requests[1].headers['Authorization'], 'Bearer opaque-access-one');
      expect(auth.identity?.email, 'persona@example.com');
      expect(auth.identity?.roles, ['SUPER_ADMIN']);
    },
  );

  for (final reason in [
    'Correo o contraseña inválidos',
    'La identidad está bloqueada temporalmente',
    'La identidad no está activa',
  ]) {
    test('401 safely denies access: $reason', () async {
      var count = 0;
      final auth = createAuth(
        handler: (_) async {
          count++;
          return errorResponse(401, message: reason);
        },
      );
      addTearDown(auth.dispose);
      expect(await auth.login('persona@example.com', 'password'), isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.identity, isNull);
      expect(count, 1);
      expect(auth.failure?.correlationId, 'support-12345');
      expect(auth.failure?.message, reason);
      expect(auth.failure?.supportMessage, reason);
    });
  }

  for (final status in [400, 403, 429, 500]) {
    test('failed login retains error.message for HTTP $status', () async {
      const message = 'El servicio no puede iniciar esta sesión.';
      final auth = createAuth(
        handler: (_) async => errorResponse(status, message: message),
      );
      addTearDown(auth.dispose);
      expect(await auth.login('persona@example.com', 'password'), isFalse);
      expect(auth.failure?.message, message);
      expect(auth.failure?.supportMessage, message);
      expect(auth.failure?.correlationId, 'support-12345');
    });
  }

  for (final body in [
    '<html>Proxy error</html>',
    jsonEncode({
      'error': {'message': null},
    }),
    jsonEncode({
      'error': {'message': 123},
    }),
    jsonEncode({
      'error': {'message': '   '},
    }),
    jsonEncode({'error': {}}),
  ]) {
    test(
      'failed login falls back when error.message is invalid: $body',
      () async {
        final auth = createAuth(handler: (_) async => http.Response(body, 401));
        addTearDown(auth.dispose);
        expect(await auth.login('persona@example.com', 'password'), isFalse);
        expect(auth.failure?.serverMessage, isNull);
        expect(
          auth.failure?.message,
          startsWith('No se pudo autorizar el acceso.'),
        );
      },
    );
  }

  test('login shares one in-flight operation for direct callers', () async {
    final pending = Completer<http.Response>();
    var count = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          count++;
          return pending.future;
        }
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    final first = auth.login('persona@example.com', 'password');
    final second = auth.login('persona@example.com', 'password');
    expect(identical(first, second), isTrue);
    pending.complete(sessionResponse());
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(count, 1);
  });

  test(
    'returned TTL triggers a single refresh shared by protected consumers',
    () async {
      var now = DateTime.utc(2026, 10, 1);
      final rotating = Completer<http.Response>();
      final requests = <http.Request>[];
      final auth = createAuth(
        now: () => now,
        handler: (request) async {
          requests.add(request);
          if (request.url.path.endsWith('/login')) {
            return sessionResponse(expiresIn: 7);
          }
          if (request.url.path.endsWith('/refresh')) return rotating.future;
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      now = now.add(const Duration(seconds: 6));
      await auth.request('GET', '/api/v1/roles');
      expect(
        requests.last.headers['Authorization'],
        'Bearer opaque-access-one',
      );
      now = now.add(const Duration(seconds: 1));
      final first = auth.request('GET', '/api/v1/roles');
      final second = auth.request(
        'GET',
        '/api/v1/permissions',
        organizationId: 'org-123',
      );
      await Future<void>.delayed(Duration.zero);
      expect(requests.where((r) => r.url.path.endsWith('/refresh')).length, 1);
      final refresh = requests.firstWhere(
        (r) => r.url.path.endsWith('/refresh'),
      );
      expect(jsonDecode(refresh.body), {'refreshToken': 'opaque-refresh-one'});
      rotating.complete(
        sessionResponse(status: 200, suffix: 'two', expiresIn: 3),
      );
      await Future.wait([first, second]);
      expect(
        requests
            .skip(requests.length - 2)
            .every(
              (r) => r.headers['Authorization'] == 'Bearer opaque-access-two',
            ),
        isTrue,
      );
      expect(requests.last.headers['X-Organization-Id'], 'org-123');
      now = now.add(const Duration(seconds: 3));
      await auth.request('GET', '/api/v1/roles');
      expect(
        jsonDecode(
          requests.lastWhere((r) => r.url.path.endsWith('/refresh')).body,
        ),
        {'refreshToken': 'opaque-refresh-two'},
      );
    },
  );

  for (final code in [401, 500]) {
    test(
      'failed refresh $code clears identity and stops protected requests',
      () async {
        var now = DateTime.utc(2026, 10, 1);
        var refreshes = 0;
        var protected = 0;
        final auth = createAuth(
          now: () => now,
          handler: (request) async {
            if (request.url.path.endsWith('/login')) {
              return sessionResponse(expiresIn: 1);
            }
            if (request.url.path.endsWith('/refresh')) {
              refreshes++;
              return errorResponse(code);
            }
            if (request.url.path.endsWith('/roles')) protected++;
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        now = now.add(const Duration(seconds: 1));
        await expectLater(
          auth.request('GET', '/api/v1/roles'),
          throwsA(isA<ApiFailure>()),
        );
        expect(auth.isAuthenticated, isFalse);
        expect(auth.identity, isNull);
        await expectLater(
          auth.request('GET', '/api/v1/roles'),
          throwsA(isA<ApiFailure>()),
        );
        expect(refreshes, 1);
        expect(protected, 0);
      },
    );
  }

  test(
    'revoked protected session is cleared without replaying a mutation',
    () async {
      var attempts = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/organizations')) {
            attempts++;
            return errorResponse(401);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      await expectLater(
        auth.request(
          'POST',
          '/api/v1/organizations',
          body: {'name': 'Example'},
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(auth.isAuthenticated, isFalse);
      expect(attempts, 1);
    },
  );

  test(
    'logout calls real endpoint and clears local state on bodyless 204',
    () async {
      http.Request? logout;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/logout')) logout = request;
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      await auth.logout();
      expect(logout?.method, 'POST');
      expect(logout?.headers['Authorization'], 'Bearer opaque-access-one');
      expect(auth.identity, isNull);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.failure, isNull);
    },
  );

  test(
    'logout during refresh revokes rotated session and cannot restore access',
    () async {
      var now = DateTime.utc(2026, 10, 1);
      final pending = Completer<http.Response>();
      String? revoked;
      final auth = createAuth(
        now: () => now,
        handler: (request) async {
          if (request.url.path.endsWith('/login')) {
            return sessionResponse(expiresIn: 1);
          }
          if (request.url.path.endsWith('/refresh')) return pending.future;
          if (request.url.path.endsWith('/logout')) {
            revoked = request.headers['Authorization'];
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      now = now.add(const Duration(seconds: 1));
      final failedRequest = expectLater(
        auth.request('GET', '/api/v1/roles'),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(Duration.zero);
      final logout = auth.logout();
      expect(auth.isAuthenticated, isFalse);
      pending.complete(sessionResponse(status: 200, suffix: 'two'));
      await Future.wait([logout, failedRequest]);
      expect(revoked, 'Bearer opaque-access-two');
      expect(auth.identity, isNull);
    },
  );

  test('logout during pending login revokes late issued session', () async {
    final pending = Completer<http.Response>();
    var revocations = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) return pending.future;
        if (request.url.path.endsWith('/logout')) revocations++;
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    final login = auth.login('persona@example.com', 'password');
    final logout = auth.logout();
    pending.complete(sessionResponse());
    expect(await login, isFalse);
    await logout;
    expect(auth.isAuthenticated, isFalse);
    expect(revocations, 1);
  });

  test('network failure during logout still clears local state', () async {
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/logout')) {
          throw http.ClientException('sensitive raw text');
        }
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    await auth.logout();
    expect(auth.identity, isNull);
    expect(auth.notice, contains('no pudimos confirmar'));
    expect(auth.failure?.kind, ApiFailureKind.network);
    expect(auth.failure?.message, isNot(contains('sensitive')));
  });

  for (final code in [400, 429, 500]) {
    test(
      'login falls back for HTTP $code without a message and omits details',
      () async {
        final auth = createAuth(
          handler: (_) async => jsonResponse({
            'error': {
              'correlationId': 'support-12345',
              'details': 'Internal details',
            },
          }, code),
        );
        addTearDown(auth.dispose);
        expect(await auth.login('persona@example.com', 'password'), isFalse);
        expect(auth.failure?.supportMessage, contains('support-12345'));
        expect(
          auth.failure?.supportMessage,
          isNot(contains('Internal details')),
        );
      },
    );
  }

  test(
    'malformed and wrong-status success responses cannot authenticate',
    () async {
      for (final response in [
        http.Response('<html>proxy error</html>', 201),
        jsonResponse({'data': {}}, 201),
        sessionResponse(status: 200),
      ]) {
        final auth = createAuth(handler: (_) async => response);
        expect(await auth.login('persona@example.com', 'password'), isFalse);
        expect(auth.failure?.kind, ApiFailureKind.unexpected);
        expect(auth.isAuthenticated, isFalse);
        auth.dispose();
      }
    },
  );

  test('me failure denies authentication and revokes issued session', () async {
    var revoked = false;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/me')) return errorResponse(500);
        if (request.url.path.endsWith('/logout')) revoked = true;
        return defaultHandler(request);
      },
    );
    addTearDown(auth.dispose);
    expect(await auth.login('persona@example.com', 'password'), isFalse);
    expect(auth.identity, isNull);
    expect(revoked, isTrue);
  });

  test(
    'network and timeout login errors never expose raw exceptions',
    () async {
      for (final hang in [false, true]) {
        final auth = createAuth(
          timeout: const Duration(milliseconds: 5),
          handler: (_) async {
            if (hang) return Completer<http.Response>().future;
            throw http.ClientException('password=secret');
          },
        );
        expect(await auth.login('persona@example.com', 'password'), isFalse);
        expect(auth.failure?.kind, ApiFailureKind.network);
        expect(auth.failure.toString(), isNot(contains('secret')));
        auth.dispose();
      }
    },
  );

  test('missing configuration produces safe feedback', () async {
    final api = AuthApiClient(null, http.Client());
    addTearDown(api.close);
    await expectLater(
      api.login('persona@example.com', 'password'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.configuration,
        ),
      ),
    );
  });
}
