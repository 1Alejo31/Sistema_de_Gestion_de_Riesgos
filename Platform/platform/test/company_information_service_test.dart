import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/services/company_information_service.dart';

import 'support/auth_fixtures.dart';

void main() {
  for (final status in [400, 403, 409, 500]) {
    test(
      'company service preserves session and reports HTTP $status',
      () async {
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path.endsWith('/company-profile')) {
              return errorResponse(
                status,
                message: 'Revisa los datos de la empresa.',
              );
            }
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        await expectLater(
          CompanyInformationService(auth).request(
            'org-1',
            'company-profile',
            method: 'PUT',
            body: {'expectedVersion': 2},
          ),
          throwsA(
            isA<ApiFailure>().having((e) => e.statusCode, 'status', status),
          ),
        );
        expect(auth.isAuthenticated, isTrue);
      },
    );
  }

  for (final payload in [
    '<html>Error</html>',
    jsonEncode({'data': null}),
    jsonEncode({
      'data': {'organizationId': 'other-company'},
    }),
    jsonEncode({'data': []}),
  ]) {
    test(
      'company service rejects malformed or foreign profile: $payload',
      () async {
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path.endsWith('/company-profile')) {
              return http.Response(
                payload,
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        await expectLater(
          CompanyInformationService(auth).request('org-1', 'company-profile'),
          throwsA(isA<ApiFailure>()),
        );
      },
    );
  }

  test(
    'company creation can retry unchanged body and idempotency key with current Bearer',
    () async {
      final posts = <http.Request>[];
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/processes')) {
            posts.add(request);
            if (posts.length == 1) return errorResponse(500);
            return jsonResponse({
              'data': {
                'id': 'process-1',
                'organizationId': 'org-1',
                'name': 'Compras',
                'status': 'ACTIVE',
              },
            }, 201);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      final service = CompanyInformationService(auth);
      Future<dynamic> create() => service.request(
        'org-1',
        'processes',
        method: 'POST',
        body: {'name': 'Compras'},
        idempotencyKey: 'creation-test-001',
      );
      await expectLater(create(), throwsA(isA<ApiFailure>()));
      expect((await create())['id'], 'process-1');
      expect(posts.length, 2);
      expect(posts.first.body, posts.last.body);
      expect(posts.last.headers['Authorization'], 'Bearer opaque-access-one');
      expect(posts.last.headers['X-Organization-Id'], 'org-1');
      expect(
        posts.last.headers['Idempotency-Key'],
        posts.first.headers['Idempotency-Key'],
      );
    },
  );
}
