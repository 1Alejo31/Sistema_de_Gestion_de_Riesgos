import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:landing_page/config/api_config.dart';
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/services/auth_api_client.dart';
import 'package:landing_page/services/organizations_service.dart';

import 'support/auth_fixtures.dart';

void main() {
  test(
    'list organizations uses the global endpoint and Bearer session',
    () async {
      http.Request? request;
      final auth = AuthController(
        AuthApiClient(
          ApiConfig.fromEnvironment(),
          MockClient((value) async {
            if (value.url.path == '/api/v1/organizations') {
              request = value;
              return jsonResponse({
                'data': [
                  {
                    '_id': 'organization-1',
                    'legalId': '900123456-7',
                    'legalName': 'Empresa Ejemplo S.A.S.',
                    'status': 'ACTIVE',
                    'createdAt': '2026-10-14T12:00:00.000Z',
                  },
                ],
              }, 200);
            }
            return defaultHandler(value);
          }),
        ),
      );
      addTearDown(auth.dispose);
      await auth.login('admin@example.com', 'password');

      final organizations = await OrganizationsService(
        auth,
      ).listOrganizations();

      expect(request?.method, 'GET');
      expect(
        request?.url.toString(),
        'http://3.148.192.204/api/v1/organizations',
      );
      expect(request?.headers['Authorization'], 'Bearer opaque-access-one');
      expect(request?.headers.containsKey('X-Organization-Id'), isFalse);
      expect(organizations.single.id, 'organization-1');
      expect(organizations.single.legalId, '900123456-7');
      expect(organizations.single.legalName, 'Empresa Ejemplo S.A.S.');
    },
  );

  test('create organization posts legal data and administrator ID', () async {
    http.Request? request;
    final auth = AuthController(
      AuthApiClient(
        ApiConfig.fromEnvironment(),
        MockClient((value) async {
          if (value.url.path == '/api/v1/organizations' &&
              value.method == 'POST') {
            request = value;
            return jsonResponse({
              'data': {
                '_id': 'organization-2',
                'legalId': '900123456-7',
                'legalName': 'Empresa Ejemplo S.A.S.',
                'status': 'ACTIVE',
                'createdAt': '2026-10-14T12:00:00.000Z',
              },
            }, 201);
          }
          return defaultHandler(value);
        }),
      ),
    );
    addTearDown(auth.dispose);
    await auth.login('admin@example.com', 'password');

    final created = await OrganizationsService(auth).createOrganization(
      legalId: ' 900123456-7 ',
      legalName: ' Empresa Ejemplo S.A.S. ',
      administratorId: 'active-admin-id',
    );

    expect(request?.method, 'POST');
    expect(
      request?.url.toString(),
      'http://3.148.192.204/api/v1/organizations',
    );
    expect(request?.headers['Authorization'], 'Bearer opaque-access-one');
    expect(request?.headers['Content-Type'], 'application/json');
    expect(jsonDecode(request!.body), {
      'legalId': '900123456-7',
      'legalName': 'Empresa Ejemplo S.A.S.',
      'administratorId': 'active-admin-id',
    });
    expect(created.id, 'organization-2');
    expect(auth.isAuthenticated, isTrue);
  });

  test('organization API errors expose server message', () async {
    final auth = createAuth(
      handler: (request) async => request.url.path == '/api/v1/organizations'
          ? errorResponse(
              403,
              message: 'Solo un superadministrador puede registrar empresas.',
            )
          : defaultHandler(request),
    );
    addTearDown(auth.dispose);
    await auth.login('admin@example.com', 'password');

    await expectLater(
      OrganizationsService(auth).createOrganization(
        legalId: '900123456-7',
        legalName: 'Empresa Ejemplo S.A.S.',
        administratorId: 'active-admin-id',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          'Solo un superadministrador puede registrar empresas.',
        ),
      ),
    );
  });
}
