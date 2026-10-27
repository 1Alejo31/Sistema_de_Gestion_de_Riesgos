import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/main.dart';
import 'package:landing_page/models/api_failure.dart';
import 'package:landing_page/views/accounts_page.dart';
import 'package:landing_page/views/change_password_page.dart';
import 'package:landing_page/views/home_page.dart';
import 'package:landing_page/views/login_page.dart';
import 'package:landing_page/views/organizations_page.dart';
import 'package:landing_page/widgets/dashboard_widgets.dart';

import 'support/auth_fixtures.dart';

http.Response me(List<String> roles, {bool required = false}) => jsonResponse({
  'data': {
    'id': 'identity-one',
    'email': 'persona@example.com',
    'status': 'ACTIVE',
    'roles': roles,
    'scope': 'GLOBAL',
    'passwordChangeRequired': required,
  },
}, 200);

void main() {
  for (final source in ['login', 'me']) {
    testWidgets(
      'required password from $source blocks home and validates form',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var patches = 0;
        var changed = false;
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path.endsWith('/login') &&
                source == 'login' &&
                !changed) {
              final body =
                  jsonDecode(sessionResponse().body) as Map<String, dynamic>;
              body['data']['passwordChangeRequired'] = true;
              return jsonResponse(body, 201);
            }
            if (request.url.path.endsWith('/me')) {
              return me(['WORKER'], required: source == 'me' && !changed);
            }
            if (request.url.path.endsWith('/password')) {
              patches++;
              expect(request.method, 'PATCH');
              expect(
                request.headers['Authorization'],
                'Bearer opaque-access-one',
              );
              expect(request.headers['Content-Type'], 'application/json');
              expect(jsonDecode(request.body), {
                'currentPassword': 'Initial-Password2026!',
                'newPassword': 'Replacement-Password2026!',
              });
              if (patches == 1) {
                return errorResponse(
                  401,
                  message: 'Contraseña actual incorrecta',
                );
              }
              changed = true;
              return http.Response('', 204);
            }
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'Initial-Password2026!');
        expect(auth.passwordChangeRequired, isTrue);
        await expectLater(
          auth.request('GET', '/api/v1/users'),
          throwsA(isA<ApiFailure>()),
        );
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: MyApp(
              authController: auth,
              initialRoute: '/home',
              theme: ThemeData(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(ChangePasswordPage), findsOneWidget);
        final submit = find.byKey(const Key('change_password_submit'));
        Future<void> send() async {
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await tester.pumpAndSettle();
        }

        await send();
        expect(patches, 0);
        await tester.enterText(
          find.byKey(const Key('change_current_password')),
          'Initial-Password2026!',
        );
        await tester.enterText(
          find.byKey(const Key('change_new_password')),
          'Initial-Password2026!',
        );
        await tester.enterText(
          find.byKey(const Key('change_confirm_password')),
          'other',
        );
        await send();
        expect(
          find.text('La nueva contraseña debe ser distinta de la actual.'),
          findsOneWidget,
        );
        expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
        expect(patches, 0);
        await tester.enterText(
          find.byKey(const Key('change_new_password')),
          'Replacement-Password2026!',
        );
        await tester.enterText(
          find.byKey(const Key('change_confirm_password')),
          'Replacement-Password2026!',
        );
        await send();
        expect(find.text('Contraseña actual incorrecta'), findsOneWidget);
        expect(auth.isAuthenticated, isTrue);
        await send();
        expect(patches, 2);
        expect(auth.isAuthenticated, isFalse);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(
          find.textContaining('Contraseña actualizada correctamente.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('login_email')),
          'persona@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'Replacement-Password2026!',
        );
        await tester.ensureVisible(find.byKey(const Key('login_submit')));
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(HomePage), findsOneWidget);
        expect(auth.passwordChangeRequired, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final roles in <List<String>>[
    [],
    ['WORKER'],
    ['ORGANIZATION_ADMIN'],
    ['WORKER', 'SUPER_ADMIN'],
  ]) {
    for (final route in ['/home', '/accounts', '/organizations']) {
      testWidgets('$roles controls organization access at $route', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1440, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var usersCalls = 0;
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path.endsWith('/me')) return me(roles);
            if (request.url.path.endsWith('/users')) usersCalls++;
            return defaultHandler(request);
          },
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'password');
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: MyApp(
              authController: auth,
              initialRoute: route,
              theme: ThemeData(),
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        final admin = roles.contains('SUPER_ADMIN');
        expect(
          find.widgetWithText(DashboardNavTile, 'Organización'),
          admin ? findsOneWidget : findsNothing,
        );
        if (!admin) {
          expect(find.byType(AccountsPage), findsNothing);
          expect(find.byType(OrganizationsPage), findsNothing);
          expect(usersCalls, 0);
          expect(find.byType(HomePage), findsOneWidget);
        } else if (route == '/accounts') {
          expect(find.byType(AccountsPage), findsOneWidget);
        } else if (route == '/organizations') {
          expect(find.byType(OrganizationsPage), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
