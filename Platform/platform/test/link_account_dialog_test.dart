import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/main.dart';
import 'package:landing_page/widgets/link_account_dialog.dart';

import 'support/auth_fixtures.dart';
import 'support/users_fixtures.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  for (final retryEmpty in [false, true]) {
    testWidgets(
      'linking refreshes cached empty companies and can reload an empty result, retry=$retryEmpty',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1440, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var reads = 0;
        final pending = Completer<http.Response>();
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path == '/api/v1/users') return usersResponse();
            if (request.url.path == '/api/v1/organizations') {
              reads++;
              expect(request.method, 'GET');
              expect(
                request.headers['Authorization'],
                'Bearer opaque-access-one',
              );
              if (reads == 1 || (retryEmpty && reads == 2)) {
                return jsonResponse({'data': []}, 200);
              }
              return pending.future;
            }
            return defaultHandler(request);
          },
        );
        await auth.login('admin@example.com', 'password');
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: MyApp(
              authController: auth,
              initialRoute: '/accounts',
              theme: ThemeData(),
            ),
          ),
        );
        await settle(tester);
        expect(reads, 1);
        await tester.ensureVisible(find.byTooltip('Editar cuenta').first);
        await tester.tap(find.byTooltip('Editar cuenta').first);
        await settle(tester);
        expect(reads, 2);
        if (retryEmpty) {
          expect(find.byKey(const Key('link_organization')), findsNothing);
          await tester.tap(find.byKey(const Key('link_organizations_reload')));
          await settle(tester);
          expect(reads, 3);
        }
        // While the fresh request is pending, don't open an empty snapshot.
        expect(find.byKey(const Key('link_organization')), findsNothing);
        expect(find.text('No hay opciones para esta búsqueda.'), findsNothing);
        pending.complete(
          jsonResponse({
            'data': [
              {
                'id': 'fresh-company',
                'legalName': 'Empresa actualizada',
                'legalId': '900123456-7',
                'status': 'ACTIVE',
                'createdAt': '2026-10-14T12:00:00Z',
              },
            ],
          }, 200),
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('link_organization')));
        await settle(tester);
        final search = find.byKey(const Key('link_organization_search'));
        await tester.enterText(search, 'no existe');
        await settle(tester);
        expect(
          find.text('No hay opciones para esta búsqueda.'),
          findsOneWidget,
        );
        await tester.enterText(search, '900123456');
        await settle(tester);
        expect(
          find.byKey(const ValueKey('link_organization_fresh-company')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('link_organization_fresh-company')),
        );
        await settle(tester);
        expect(find.byKey(const Key('link_role')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final size in [const Size(1440, 900), const Size(320, 640)]) {
    testWidgets(
      'links selected account with searchable company, role and scope at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final posts = <http.Request>[];
        final membershipReads = <String, int>{};
        final paths = <String>[];
        final auth = createAuth(
          handler: (request) async {
            paths.add(request.url.path);
            if (request.url.path == '/api/v1/users') return usersResponse();
            if (request.url.path == '/api/v1/organizations') {
              return jsonResponse({
                'data': [
                  for (var i = 1; i <= 2; i++)
                    {
                      'id': 'org-$i',
                      'legalId': '90012345$i-7',
                      'legalName': 'Empresa $i',
                      'status': 'ACTIVE',
                      'createdAt': '2026-10-14T12:00:00Z',
                    },
                ],
              }, 200);
            }
            if (request.url.path == '/api/v1/roles') {
              return jsonResponse({
                'data': [
                  {'role': 'WORKER', 'permissions': []},
                  {'role': 'SST_MANAGER', 'permissions': []},
                ],
              }, 200);
            }
            if (request.url.path.endsWith('/memberships')) {
              expect(
                request.headers['Authorization'],
                'Bearer opaque-access-one',
              );
              if (request.method == 'POST') {
                posts.add(request);
                if (posts.length == 1) {
                  return errorResponse(409, message: 'Conflicto de prueba');
                }
                return jsonResponse({
                  'data': {
                    'id': accountItems.first['id'],
                    'email': accountItems.first['email'],
                    'organizationId': 'org-2',
                    'membership': {
                      'role': 'WORKER',
                      'scope': {'type': 'ORGANIZATION'},
                      'status': 'ACTIVE',
                    },
                  },
                }, 201);
              }
              membershipReads.update(
                request.url.path,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
              return jsonResponse({
                'data': [
                  {
                    'scope': {'type': 'ORGANIZATION'},
                  },
                  {
                    'scope': {'type': 'SITE', 'id': 'sede-1'},
                  },
                  {
                    'scope': {'type': 'SITE', 'id': 'sede-1'},
                  },
                  {
                    'scope': {'type': 'PROCESS', 'id': 'proceso-1'},
                  },
                ],
              }, 200);
            }
            return defaultHandler(request);
          },
        );
        await auth.login('persona@example.com', 'password');
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: MyApp(
              authController: auth,
              initialRoute: '/accounts',
              theme: ThemeData(),
            ),
          ),
        );
        await settle(tester);
        await tester.ensureVisible(find.byTooltip('Editar cuenta').first);
        await tester.tap(find.byTooltip('Editar cuenta').first);
        await settle(tester);
        expect(find.byType(LinkAccountDialog), findsOneWidget);
        expect(find.byKey(const Key('link_account_email')), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byKey(const Key('link_role')), findsNothing);

        Future<void> choose(String field, String query, String option) async {
          await tester.ensureVisible(find.byKey(Key(field)));
          await tester.tap(find.byKey(Key(field)));
          await settle(tester);
          await tester.enterText(find.byKey(Key('${field}_search')), query);
          await settle(tester);
          await tester.tap(find.byKey(ValueKey('${field}_$option')));
          await settle(tester);
        }

        await choose('link_organization', '900123451', 'org-1');
        expect(paths, contains('/api/v1/organizations/org-1/memberships'));
        await choose('link_role', 'sst_manager', 'SST_MANAGER');
        await choose('link_scope', 'sede-1', 'SITE:sede-1');
        // A different company must never retain the previous company's scope.
        await choose('link_organization', 'Empresa 2', 'org-2');
        expect(paths, contains('/api/v1/organizations/org-2/memberships'));
        await tester.ensureVisible(
          find.byKey(const Key('link_account_submit')),
        );
        await tester.tap(find.byKey(const Key('link_account_submit')));
        await settle(tester);
        expect(posts, isEmpty);
        expect(find.text('Selecciona un rol.'), findsOneWidget);
        expect(find.text('Selecciona un alcance.'), findsOneWidget);
        await choose('link_role', 'trabajador', 'WORKER');
        await choose('link_scope', 'toda', 'ORGANIZATION:');
        Future<void> submit() async {
          await tester.ensureVisible(
            find.byKey(const Key('link_account_submit')),
          );
          await tester.tap(find.byKey(const Key('link_account_submit')));
          await settle(tester);
        }

        await submit();
        expect(find.text('Conflicto de prueba'), findsOneWidget);
        await submit();
        expect(posts.length, 2);
        expect(posts.first.body, posts.last.body);
        expect(
          posts.first.headers['Idempotency-Key'],
          posts.last.headers['Idempotency-Key'],
        );
        expect(posts.first.headers['Idempotency-Key'], isNotEmpty);
        expect(jsonDecode(posts.last.body), {
          'email': accountItems.first['email'],
          'role': 'WORKER',
          'scope': {'type': 'ORGANIZATION'},
        });
        expect(find.byKey(const Key('account_linked_alert')), findsOneWidget);
        expect(membershipReads['/api/v1/organizations/org-2/memberships'], 2);
        expect(
          find.text('Rol: Trabajador\nAlcance: Toda la empresa'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
