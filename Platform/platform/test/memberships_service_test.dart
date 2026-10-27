import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/models/membership_options.dart';
import 'package:landing_page/services/memberships_service.dart';

import 'support/auth_fixtures.dart';

void main() {
  for (final scope in [
    const MembershipScope('ORGANIZATION'),
    const MembershipScope('SITE', 'site-1'),
    const MembershipScope('PROCESS', 'process-1'),
  ]) {
    test('link sends Bearer, JSON and idempotency for ${scope.type}', () async {
      http.Request? sent;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/memberships')) {
            sent = request;
            return jsonResponse({
              'data': {
                'id': 'user-1',
                'email': 'persona@example.com',
                'organizationId': 'org-1',
                'membership': {
                  'role': 'WORKER',
                  'scope': scope.toJson(),
                  'status': 'ACTIVE',
                },
              },
            }, 201);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      final result = await MembershipsService(auth).link(
        organizationId: 'org-1',
        email: 'persona@example.com',
        role: 'WORKER',
        scope: scope,
        idempotencyKey: 'link-test-001',
      );
      expect(sent?.method, 'POST');
      expect(sent?.url.path, '/api/v1/organizations/org-1/memberships');
      expect(sent?.headers['Authorization'], 'Bearer opaque-access-one');
      expect(sent?.headers['Content-Type'], 'application/json');
      expect(sent?.headers['Accept'], 'application/json');
      expect(sent?.headers['Idempotency-Key'], 'link-test-001');
      expect(jsonDecode(sent!.body), {
        'email': 'persona@example.com',
        'role': 'WORKER',
        'scope': scope.toJson(),
      });
      expect(result.accountId, 'user-1');
      expect(result.organizationId, 'org-1');
      expect(result.role, 'WORKER');
      expect(result.scope.key, scope.key);
    });
  }

  for (final status in [400, 401, 403, 404, 409, 500]) {
    test(
      'link handles HTTP $status and preserves session except on 401',
      () async {
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path.endsWith('/memberships')) {
              return errorResponse(
                status,
                message: 'Mensaje de prueba del servicio',
              );
            }
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        await expectLater(
          MembershipsService(auth).link(
            organizationId: 'org-1',
            email: 'persona@example.com',
            role: 'WORKER',
            idempotencyKey: 'link-test-001',
          ),
          throwsA(
            isA<ApiFailure>()
                .having((error) => error.statusCode, 'status', status)
                .having(
                  (error) => error.serverMessage,
                  'server message',
                  status == 500 ? isNull : 'Mensaje de prueba del servicio',
                )
                .having(
                  (error) => error.correlationId,
                  'reference',
                  'support-12345',
                ),
          ),
        );
        expect(auth.isAuthenticated, status != 401);
      },
    );
  }

  test(
    'link rejects incomplete success payloads and mismatched companies',
    () async {
      var attempts = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/memberships')) {
            attempts++;
            return jsonResponse({
              'data': attempts == 1
                  ? {'id': 'user-1'}
                  : {
                      'id': 'user-1',
                      'email': 'persona@example.com',
                      'organizationId': 'another-org',
                      'membership': {
                        'role': 'WORKER',
                        'scope': {'type': 'ORGANIZATION'},
                        'status': 'ACTIVE',
                      },
                    },
            }, 201);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      for (var i = 0; i < 2; i++) {
        await expectLater(
          MembershipsService(auth).link(
            organizationId: 'org-1',
            email: 'persona@example.com',
            role: 'WORKER',
            idempotencyKey: 'link-test-001',
          ),
          throwsA(isA<ApiFailure>()),
        );
      }
    },
  );
  test(
    'scope options include organization and deduplicate specific scopes',
    () async {
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/memberships')) {
            return jsonResponse({
              'data': [
                {
                  'scope': {'type': 'SITE', 'id': 'site-1'},
                },
                {
                  'scope': {'type': 'SITE', 'id': 'site-1'},
                },
                {
                  'scope': {'type': 'PROCESS', 'id': 'process-1'},
                },
              ],
            }, 200);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      final scopes = await MembershipsService(auth).scopes('org-1');
      expect(scopes.map((scope) => scope.key), [
        'ORGANIZATION:',
        'SITE:site-1',
        'PROCESS:process-1',
      ]);
      expect(scopes[1].toJson(), {'type': 'SITE', 'id': 'site-1'});
    },
  );
  test(
    'malformed scope response fails without inventing assignable resources',
    () async {
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/memberships')) {
            return jsonResponse({
              'data': [
                {
                  'scope': {'type': 'SITE'},
                },
              ],
            }, 200);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'password');
      await expectLater(
        MembershipsService(auth).scopes('org-1'),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
}
