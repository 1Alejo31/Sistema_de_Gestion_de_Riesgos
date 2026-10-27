import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/main.dart';
import 'package:landing_page/providers/organizations_providers.dart';
import 'package:landing_page/widgets/organization_selector.dart';

import 'support/auth_fixtures.dart';

final _items = List.generate(
  25,
  (i) => {
    'id': 'organization-$i',
    'legalId': '9000000$i-7',
    'legalName': i == 24 ? 'Empresa buscada' : 'Empresa $i',
    'status': 'ACTIVE',
    'createdAt': '2026-10-14T12:00:00.000Z',
  },
);

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  for (final size in [const Size(1440, 900), const Size(320, 640)]) {
    testWidgets('menu fetches, searches and selects real companies at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<http.Response>();
      var requests = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/organizations') {
            requests++;
            expect(request.method, 'GET');
            expect(
              request.headers['Authorization'],
              'Bearer opaque-access-one',
            );
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
            initialRoute: '/home',
            theme: ThemeData(),
          ),
        ),
      );
      await settle(tester);
      if (size.width < 1100) {
        tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
        await settle(tester);
      }
      expect(find.text('12 empresas'), findsNothing);
      expect(find.text('Cargando empresas…'), findsWidgets);
      pending.complete(jsonResponse({'data': _items}, 200));
      await settle(tester);
      expect(find.text('25 empresas'), findsWidgets);
      await tester.tap(find.byKey(const Key('organization_selector')).first);
      await settle(tester);
      final search = find.byKey(const Key('organization_picker_search'));
      await tester.enterText(search, 'no existe');
      await settle(tester);
      expect(
        find.text('No hay empresas que coincidan con la búsqueda.'),
        findsOneWidget,
      );
      await tester.enterText(search, 'BUSCADA');
      await settle(tester);
      expect(find.byType(ListTile), findsOneWidget);
      await tester.enterText(search, '900000024-7');
      await settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('select_organization_organization-24')),
      );
      await settle(tester);
      expect(find.byKey(const Key('organization_picker')), findsNothing);
      expect(find.text('Empresa buscada'), findsWidgets);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OrganizationSelector).first),
      );
      expect(
        container.read(selectedOrganizationProvider)?.id,
        'organization-24',
      );
      expect(requests, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('menu retries loading failures and shows an empty list', (
    tester,
  ) async {
    var requests = 0;
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path == '/api/v1/organizations') {
          return ++requests == 1
              ? errorResponse(500)
              : jsonResponse({'data': []}, 200);
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
          initialRoute: '/home',
          theme: ThemeData(),
        ),
      ),
    );
    await settle(tester);
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await settle(tester);
    await tester.tap(find.byKey(const Key('organization_selector')).first);
    await settle(tester);
    expect(
      find.text('No se pudo cargar el listado de empresas.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await settle(tester);
    expect(find.text('No tienes empresas disponibles.'), findsOneWidget);
    expect(requests, 2);
    expect(auth.isAuthenticated, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
