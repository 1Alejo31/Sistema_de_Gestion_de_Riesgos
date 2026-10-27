import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:landing_page/config/api_config.dart';
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/services/auth_api_client.dart';
import 'package:landing_page/services/users_service.dart';
import 'dart:convert';

import 'support/auth_fixtures.dart';
import 'support/users_fixtures.dart';

void main() {
  test('users uses the global API and the shared session Bearer', () async {
    http.Request? usersRequest;
    final auth = AuthController(
      AuthApiClient(
        ApiConfig.fromEnvironment(),
        MockClient((request) async {
          if (request.url.path == '/api/v1/users') {
            usersRequest = request;
            return usersResponse();
          }
          return defaultHandler(request);
        }),
      ),
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    final users = await UsersService(auth).listUsers();
    expect(usersRequest?.method, 'GET');
    expect(usersRequest?.url.toString(), 'http://3.148.192.204/api/v1/users');
    expect(usersRequest?.headers['Authorization'], 'Bearer opaque-access-one');
    expect(usersRequest?.headers.containsKey('X-Organization-Id'), isFalse);
    expect(users.length, 2);
    expect(users.first.email, 'demo.observer@sgsst.invalid');
    expect(users.first.roles, isEmpty);
    expect(users.last.roles, ['SUPER_ADMIN']);
    expect(
      users.first.createdAt.toUtc().toIso8601String(),
      '2026-10-12T21:54:52.192Z',
    );
  });

  test('forbidden users request preserves the authenticated session', () async {
    final auth = createAuth(
      handler: (request) async => request.url.path == '/api/v1/users'
          ? errorResponse(403)
          : defaultHandler(request),
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    await expectLater(
      UsersService(auth).listUsers(),
      throwsA(
        isA<ApiFailure>().having(
          (error) => error.kind,
          'kind',
          ApiFailureKind.forbidden,
        ),
      ),
    );
    expect(auth.isAuthenticated, isTrue);
  });

  test('empty accounts response is an empty list', () async {
    final auth = createAuth(
      handler: (request) async => request.url.path == '/api/v1/users'
          ? usersResponse(items: [])
          : defaultHandler(request),
    );
    addTearDown(auth.dispose);
    await auth.login('persona@example.com', 'password');
    expect(await UsersService(auth).listUsers(), isEmpty);
  });

  test(
    'create user sends the shared superadmin Bearer and idempotency key',
    () async {
      http.Request? createRequest;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/users' && request.method == 'POST') {
            createRequest = request;
            return jsonResponse({
              'data': {
                'id': 'created-user-id',
                'email': 'persona.nueva@example.com',
                'roles': <String>[],
                'status': 'ACTIVE',
                'scope': 'GLOBAL',
                'createdAt': '2026-10-14T12:00:00.000Z',
              },
            }, 201);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('admin@example.com', 'admin-password');

      final created = await UsersService(auth).createUser(
        email: 'persona.nueva@example.com',
        password: 'ClaveSegura-2026!',
        idempotencyKey: 'create-account-2026-001',
      );

      expect(createRequest?.method, 'POST');
      expect(
        createRequest?.url.toString(),
        'https://api.example.com/api/v1/users',
      );
      expect(
        createRequest?.headers['Authorization'],
        'Bearer opaque-access-one',
      );
      expect(
        createRequest?.headers['Idempotency-Key'],
        'create-account-2026-001',
      );
      expect(jsonDecode(createRequest!.body), {
        'email': 'persona.nueva@example.com',
        'password': 'ClaveSegura-2026!',
      });
      expect(created.email, 'persona.nueva@example.com');
      expect(created.roles, isEmpty);
      expect(created.status, 'ACTIVE');
    },
  );

  test(
    'create user surfaces server message and keeps session on conflict',
    () async {
      final auth = createAuth(
        handler: (request) async => request.url.path == '/api/v1/users'
            ? errorResponse(409, message: 'El correo ya está registrado.')
            : defaultHandler(request),
      );
      addTearDown(auth.dispose);
      await auth.login('admin@example.com', 'admin-password');

      await expectLater(
        UsersService(auth).createUser(
          email: 'existing@example.com',
          password: 'ClaveSegura-2026!',
          idempotencyKey: 'create-account-2026-002',
        ),
        throwsA(
          isA<ApiFailure>()
              .having(
                (error) => error.message,
                'message',
                'El correo ya está registrado.',
              )
              .having(
                (error) => error.correlationId,
                'correlationId',
                'support-12345',
              ),
        ),
      );
      expect(auth.isAuthenticated, isTrue);
    },
  );

  for (final response in [
    http.Response('<html>Proxy failure</html>', 200),
    jsonResponse({'data': []}, 200),
    usersResponse(items: [null]),
    usersResponse(
      items: [
        {
          ...accountItems.first,
          'roles': [123],
        },
      ],
    ),
    usersResponse(
      items: [
        {...accountItems.first, 'createdAt': 'bad-date'},
      ],
    ),
  ]) {
    test(
      'malformed users response yields a controlled error: ${response.body}',
      () async {
        final auth = createAuth(
          handler: (request) async => request.url.path == '/api/v1/users'
              ? response
              : defaultHandler(request),
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        await expectLater(
          UsersService(auth).listUsers(),
          throwsA(
            isA<ApiFailure>().having(
              (error) => error.kind,
              'kind',
              ApiFailureKind.unexpected,
            ),
          ),
        );
      },
    );
  }
}
