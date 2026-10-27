import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/main.dart';
import 'package:landing_page/views/home_page.dart';
import 'package:landing_page/views/login_page.dart';

import 'support/auth_fixtures.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    AuthController auth, {
    String route = '/login',
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(auth.dispose);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'persona@example.com',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'password');
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
  }

  testWidgets(
    'direct home without a session redirects and removes protected history',
    (tester) async {
      await mount(tester, createAuth(), route: '/home');
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'login stays pending, disables repeat submit and opens home only on success',
    (tester) async {
      final pending = Completer<http.Response>();
      var logins = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/login')) {
            logins++;
            return pending.future;
          }
          return defaultHandler(request);
        },
      );
      await mount(tester, auth);
      await submit(tester);
      expect(find.byType(HomePage), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('login_submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      expect(logins, 1);
      pending.complete(sessionResponse());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('demo_notice')), findsOneWidget);
      expect(find.textContaining('María González · Directora'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final reason in [
    'Correo o contraseña inválidos',
    'La identidad está bloqueada temporalmente',
    'La identidad no está activa',
  ]) {
    testWidgets('login denial displays the service message: $reason', (
      tester,
    ) async {
      await mount(
        tester,
        createAuth(handler: (_) async => errorResponse(401, message: reason)),
      );
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsNothing);
      expect(find.byKey(const Key('auth_error')), findsOneWidget);
      expect(find.textContaining('support-12345'), findsNothing);
      expect(find.text(reason), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login_password')))
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 480),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'login validates fields without the removed reload message at $size',
      (tester) async {
        var requests = 0;
        await mount(
          tester,
          createAuth(
            handler: (request) async {
              requests++;
              return defaultHandler(request);
            },
          ),
          size: size,
        );
        await tester.ensureVisible(find.byKey(const Key('login_submit')));
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pumpAndSettle();
        expect(requests, 0);
        expect(find.text('Por favor ingrese su correo'), findsOneWidget);
        expect(find.text('Por favor ingrese su contraseña'), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.textContaining('Al recargar'), findsNothing);
        expect(find.text('Olvidé mi contraseña'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('home validates me before rendering and shows real identity', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var meCalls = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/me') && ++meCalls > 1) {
          return pending.future;
        }
        return defaultHandler(request);
      },
    );
    await auth.login('persona@example.com', 'password');
    await mount(tester, auth, route: '/home', size: const Size(1440, 900));
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(identityResponse());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('persona@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoked identity at protected entry redirects to login', (
    tester,
  ) async {
    var meCalls = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/me') && ++meCalls > 1) {
          return errorResponse(401);
        }
        return defaultHandler(request);
      },
    );
    await auth.login('persona@example.com', 'password');
    await mount(tester, auth, route: '/home');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Salir revokes session, clears navigation and prevents returning home',
    (tester) async {
      var revocations = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path.endsWith('/logout')) revocations++;
          return defaultHandler(request);
        },
      );
      await auth.login('persona@example.com', 'password');
      await mount(tester, auth, route: '/home');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Cuenta autenticada'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Salir'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(revocations, 1);
      expect(auth.isAuthenticated, isFalse);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
        isFalse,
      );
      Navigator.of(tester.element(find.byType(LoginPage))).pushNamed('/home');
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expiry timer renews with server TTL and failure redirects', (
    tester,
  ) async {
    var refreshes = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 2);
        }
        if (request.url.path.endsWith('/refresh')) {
          refreshes++;
          return errorResponse(401);
        }
        return defaultHandler(request);
      },
    );
    await auth.login('persona@example.com', 'password');
    await mount(tester, auth, route: '/home');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('No se pudo renovar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('60 minute deadline closes home even with a long access TTL', (
    tester,
  ) async {
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) {
          return sessionResponse(expiresIn: 7200);
        }
        return defaultHandler(request);
      },
    );
    await auth.login('persona@example.com', 'password');
    await mount(tester, auth, route: '/home');
    expect(find.byType(HomePage), findsOneWidget);
    await tester.pump(const Duration(minutes: 60));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('60 minutos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
