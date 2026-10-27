import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/controllers/auth_controller.dart';
import 'package:landing_page/main.dart';
import 'package:landing_page/views/accounts_page.dart';
import 'package:landing_page/views/login_page.dart';
import 'package:landing_page/widgets/dashboard_header.dart';
import 'package:landing_page/widgets/dashboard_widgets.dart';

import 'support/auth_fixtures.dart';
import 'support/users_fixtures.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> mount(
    WidgetTester tester,
    AuthController auth, {
    String route = '/accounts',
    Size size = const Size(1440, 900),
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
    await settle(tester);
  }

  for (final size in [const Size(1440, 900), const Size(320, 640)]) {
    testWidgets('accounts navigation retains shell and hides IDs at $size', (
      tester,
    ) async {
      final pending = Completer<http.Response>();
      var requests = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/users') {
            requests++;
            expect(
              request.headers['Authorization'],
              'Bearer opaque-access-one',
            );
            return pending.future;
          }
          return defaultHandler(request);
        },
      );
      await auth.login('persona@example.com', 'password');
      await mount(tester, auth, route: '/home', size: size);
      if (size.width < 1100) {
        tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
        await settle(tester);
      }
      await tester.ensureVisible(find.text('Organización'));
      await tester.tap(find.text('Organización'));
      await settle(tester);
      await tester.ensureVisible(find.text('Gestión de Cuentas'));
      await tester.tap(find.text('Gestión de Cuentas'));
      await settle(tester);
      expect(find.byType(AccountsPage), findsOneWidget);
      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.byKey(const Key('create_account_open')), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(find.byKey(const Key('demo_notice')), findsNothing);
      expect(find.text('Cargando cuentas…'), findsOneWidget);
      pending.complete(usersResponse());
      await settle(tester);
      final table = tester.widget<DataTable>(
        find.byKey(const Key('accounts_table')),
      );
      expect(table.columns.length, 6);
      expect(table.rows.length, 2);
      expect(find.text('demo.observer@sgsst.invalid'), findsOneWidget);
      expect(find.text('demo.consultant@sgsst.invalid'), findsOneWidget);
      expect(find.text('Sin roles'), findsOneWidget);
      expect(find.text('SUPER_ADMIN'), findsOneWidget);
      expect(find.text('ID'), findsNothing);
      expect(find.text(accountItems.first['id'] as String), findsNothing);
      expect(find.byTooltip('Editar cuenta'), findsNWidgets(2));
      expect(requests, 1);
      await tester.ensureVisible(find.byTooltip('Editar cuenta').first);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('create_account_open')));
      await tester.tap(find.byKey(const Key('create_account_open')));
      await settle(tester);
      expect(find.byKey(const Key('create_account_dialog')), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Cerrar formulario'));
      await tester.tap(find.byTooltip('Cerrar formulario'));
      await settle(tester);
      expect(requests, 1);
      expect(tester.takeException(), isNull);
      if (size.width < 1100) {
        tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
        await settle(tester);
      }
      await tester.ensureVisible(
        find.widgetWithText(DashboardNavTile, 'Resumen ejecutivo'),
      );
      await tester.tap(
        find.widgetWithText(DashboardNavTile, 'Resumen ejecutivo'),
      );
      await settle(tester);
      expect(find.byType(AccountsPage), findsNothing);
      expect(find.byKey(const Key('demo_notice')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('successful account creation refreshes table and shows alert', (
    tester,
  ) async {
    var listRequests = 0;
    http.Request? createRequest;
    const newAccount = {
      'id': 'new-user-id',
      'email': 'nueva.persona@example.com',
      'roles': <String>[],
      'status': 'ACTIVE',
      'scope': 'GLOBAL',
      'createdAt': '2026-10-14T12:00:00.000Z',
    };
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path == '/api/v1/users' && request.method == 'POST') {
          createRequest = request;
          return jsonResponse({'data': newAccount}, 201);
        }
        if (request.url.path == '/api/v1/users') {
          listRequests++;
          return usersResponse(
            items: listRequests == 1
                ? accountItems
                : [...accountItems, newAccount],
          );
        }
        return defaultHandler(request);
      },
    );
    await auth.login('admin@example.com', 'password');
    await mount(tester, auth);
    await settle(tester);
    expect(listRequests, 1);

    await tester.tap(find.byKey(const Key('create_account_open')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('create_account_email')),
      'nueva.persona@example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('create_account_submit')));
    await tester.tap(find.byKey(const Key('create_account_submit')));
    await settle(tester);

    expect(createRequest?.method, 'POST');
    expect(createRequest?.headers['Authorization'], 'Bearer opaque-access-one');
    expect(createRequest?.headers['Idempotency-Key'], isNotEmpty);
    expect(find.byKey(const Key('account_created_alert')), findsOneWidget);
    expect(find.byKey(const Key('account_created_icon')), findsOneWidget);
    expect(find.text('¡Cuenta creada con éxito!'), findsOneWidget);
    expect(find.byKey(const Key('account_created_email')), findsOneWidget);
    final sent = jsonDecode(createRequest!.body) as Map<String, dynamic>;
    expect(sent['email'], 'nueva.persona@example.com');
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('account_created_password')),
          )
          .data,
      sent['password'],
    );
    expect(listRequests, 2);
    await tester.tap(find.byKey(const Key('account_created_confirm')));
    await settle(tester);
    expect(find.byKey(const Key('account_created_alert')), findsNothing);
    expect(find.text('nueva.persona@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'accounts shows forbidden error and retries without ending session',
    (tester) async {
      var requests = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/users') {
            return ++requests == 1 ? errorResponse(403) : usersResponse();
          }
          return defaultHandler(request);
        },
      );
      await auth.login('persona@example.com', 'password');
      await mount(tester, auth);
      await settle(tester);
      expect(find.byKey(const Key('accounts_error')), findsOneWidget);
      expect(auth.isAuthenticated, isTrue);
      await tester.tap(find.text('Reintentar'));
      await settle(tester);
      expect(find.byKey(const Key('accounts_table')), findsOneWidget);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'accounts searches returned data and distinguishes empty results',
    (tester) async {
      final auth = createAuth(
        handler: (request) async => request.url.path == '/api/v1/users'
            ? usersResponse()
            : defaultHandler(request),
      );
      await auth.login('persona@example.com', 'password');
      await mount(tester, auth);
      await settle(tester);
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Buscar por correo, rol, estado o alcance…',
      );
      await tester.enterText(search, 'observer');
      await settle(tester);
      expect(
        tester
            .widget<DataTable>(find.byKey(const Key('accounts_table')))
            .rows
            .length,
        1,
      );
      await tester.enterText(search, 'sin-coincidencias');
      await settle(tester);
      expect(
        find.text('No hay cuentas que coincidan con la búsqueda.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('accounts paginates ten rows and searches all requested fields', (
    tester,
  ) async {
    var requests = 0;
    final items = List.generate(
      23,
      (index) => {
        ...accountItems.first,
        'id': 'account-$index',
        'email': 'account$index@example.com',
        'roles': [index.isEven ? 'ADMIN' : 'VIEWER'],
        'status': index < 20 ? 'ACTIVE' : 'INACTIVE',
        'scope': index < 20 ? 'GLOBAL' : 'ORGANIZATION',
      },
    );
    final auth = createAuth(
      handler: (request) async {
        if (request.url.path == '/api/v1/users') {
          requests++;
          return usersResponse(items: items);
        }
        return defaultHandler(request);
      },
    );
    await auth.login('persona@example.com', 'password');
    await mount(tester, auth);
    await settle(tester);
    DataTable table() =>
        tester.widget<DataTable>(find.byKey(const Key('accounts_table')));
    expect(table().rows.length, 10);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(table().headingRowColor?.resolve({}), isNotNull);
    for (final page in [2, 3]) {
      await tester.ensureVisible(find.byTooltip('Página siguiente'));
      await tester.tap(find.byTooltip('Página siguiente'));
      await settle(tester);
      expect(find.text('Página $page de 3'), findsOneWidget);
    }
    expect(table().rows.length, 3);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('accounts_next_page')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byTooltip('Página anterior'));
    await tester.tap(find.byTooltip('Página anterior'));
    await settle(tester);
    expect(find.text('Página 2 de 3'), findsOneWidget);
    final search = find.byKey(const Key('accounts_search'));
    for (final entry in {
      'account12@': 1,
      'VIEWER': 10,
      'INACTIVE': 3,
      'ORGANIZATION': 3,
      'viewer inactive organization': 1,
    }.entries) {
      await tester.ensureVisible(search);
      await tester.enterText(search, entry.key);
      await settle(tester);
      expect(table().rows.length, entry.value);
    }
    await tester.enterText(search, '');
    await settle(tester);
    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(requests, 1);
    await tester.ensureVisible(find.byKey(const Key('create_account_open')));
    await tester.tap(find.byKey(const Key('create_account_open')));
    await settle(tester);
    expect(find.byKey(const Key('create_account_dialog')), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar formulario'));
    await settle(tester);
    expect(requests, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('accounts sort each data column ascending and descending', (
    tester,
  ) async {
    final items = [
      {
        ...accountItems.first,
        'id': 'one',
        'email': 'a.z@example.com',
        'roles': ['VIEWER'],
        'status': 'INACTIVE',
        'scope': 'ORGANIZATION',
        'createdAt': '2026-10-04T12:00:00.000Z',
      },
      {
        ...accountItems.first,
        'id': 'two',
        'email': 'z.a@example.com',
        'roles': ['ADMIN'],
        'status': 'ACTIVE',
        'scope': 'GLOBAL',
        'createdAt': '2026-10-02T12:00:00.000Z',
      },
      {
        ...accountItems.first,
        'id': 'three',
        'email': 'b.a@example.com',
        'roles': <String>[],
        'status': 'ACTIVE',
        'scope': 'ORGANIZATION',
        'createdAt': '2026-10-01T12:00:00.000Z',
      },
      {
        ...accountItems.first,
        'id': 'four',
        'email': 'a.a@example.com',
        'roles': ['ADMIN'],
        'status': 'INACTIVE',
        'scope': 'GLOBAL',
        'createdAt': '2026-10-03T12:00:00.000Z',
      },
    ];
    final auth = createAuth(
      handler: (request) async => request.url.path == '/api/v1/users'
          ? usersResponse(items: items)
          : defaultHandler(request),
    );
    await auth.login('admin@example.com', 'password');
    await mount(tester, auth);
    await settle(tester);

    List<String> emailOrder() {
      final table = tester.widget<DataTable>(
        find.byKey(const Key('accounts_table')),
      );
      return table.rows.map((row) {
        final cell = row.cells.first.child as SizedBox;
        final tooltip = cell.child as Tooltip;
        return (tooltip.child as Text).data!;
      }).toList();
    }

    await tester.tap(find.text('Correo electrónico'));
    await settle(tester);
    final sortArrow = find.byIcon(Icons.arrow_upward);
    expect(sortArrow, findsNWidgets(5));
    for (final element in sortArrow.evaluate()) {
      expect(IconTheme.of(element).color, Colors.white);
    }
    expect(emailOrder(), [
      'a.a@example.com',
      'a.z@example.com',
      'b.a@example.com',
      'z.a@example.com',
    ]);
    await tester.tap(find.text('Correo electrónico'));
    await settle(tester);
    expect(emailOrder(), [
      'z.a@example.com',
      'b.a@example.com',
      'a.z@example.com',
      'a.a@example.com',
    ]);

    await tester.tap(find.text('Roles'));
    await settle(tester);
    expect(emailOrder(), [
      'a.a@example.com',
      'z.a@example.com',
      'b.a@example.com',
      'a.z@example.com',
    ]);
    await tester.tap(find.text('Estado'));
    await settle(tester);
    expect(emailOrder(), [
      'b.a@example.com',
      'z.a@example.com',
      'a.a@example.com',
      'a.z@example.com',
    ]);
    await tester.tap(find.text('Alcance'));
    await settle(tester);
    expect(emailOrder(), [
      'a.a@example.com',
      'z.a@example.com',
      'a.z@example.com',
      'b.a@example.com',
    ]);
    await tester.ensureVisible(find.text('Fecha de creación'));
    await tester.tap(find.text('Fecha de creación'));
    await settle(tester);
    expect(emailOrder(), [
      'b.a@example.com',
      'z.a@example.com',
      'a.a@example.com',
      'a.z@example.com',
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'accounts direct access requires login and never requests users without session',
    (tester) async {
      var usersRequests = 0;
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/users') usersRequests++;
          return defaultHandler(request);
        },
      );
      await mount(tester, auth);
      await settle(tester);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AccountsPage), findsNothing);
      expect(usersRequests, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
