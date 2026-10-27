import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/providers/auth_providers.dart';
import 'package:landing_page/views/home_page.dart';
import 'package:landing_page/views/accounts_page.dart';
import 'package:landing_page/views/organizations_page.dart';
import 'package:landing_page/widgets/dashboard_widgets.dart';

import 'support/auth_fixtures.dart';

void main() {
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets(
      'organization submenu toggles and opens both options at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = createAuth(
          handler: (request) async =>
              (request.url.path == '/api/v1/users' ||
                  request.url.path == '/api/v1/organizations')
              ? jsonResponse({
                  'data': {'items': []},
                }, 200)
              : defaultHandler(request),
        );
        addTearDown(auth.dispose);
        await auth.login('persona@example.com', 'example-password');
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: ProviderScope(
              overrides: [authControllerProvider.overrideWithValue(auth)],
              child: MaterialApp(
                home: const HomePage(),
                routes: {
                  '/accounts': (_) => const HomePage(),
                  '/organizations': (_) => const HomePage(),
                },
              ),
            ),
          ),
        );
        await tester.pump();
        if (size.width < 1100) {
          tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        final organization = find.widgetWithText(
          DashboardNavTile,
          'Organización',
        );
        expect(find.text('Gestión de Cuentas'), findsNothing);
        expect(find.text('Gestión de Empresas'), findsNothing);
        await tester.ensureVisible(organization);
        await tester.tap(organization);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Gestión de Cuentas'), findsOneWidget);
        expect(find.text('Gestión de Empresas'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.widget<DashboardNavTile>(organization).expanded, isTrue);
        expect(find.text('1. Información general de la empresa'), findsNothing);

        for (final label in ['Gestión de Cuentas', 'Gestión de Empresas']) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          final workspace = label.endsWith('Cuentas')
              ? find.byType(AccountsPage)
              : find.byType(OrganizationsPage);
          expect(workspace, findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
          Navigator.of(tester.element(workspace)).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          if (size.width < 1100) {
            tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          }
        }

        final management = find.widgetWithText(
          DashboardNavTile,
          'Gestión SG-SST',
        );
        await tester.ensureVisible(management);
        await tester.tap(management);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        const modules = [
          '1. Información general de la empresa',
          '2. Evaluación inicial',
          '3. Política SST',
          '4. Objetivos SST',
          '5. Requisitos legales',
          '6. Identificación de peligros',
          '7. Valoración de riesgos',
          '8. Programas de gestión',
          '9. Recursos',
          '10. Indicadores',
          '11. Plan anual de trabajo',
        ];
        final renderedModules = tester
            .widgetList<Text>(
              find.byWidgetPredicate(
                (widget) => widget is Text && modules.contains(widget.data),
              ),
            )
            .map((widget) => widget.data)
            .toList();
        expect(renderedModules, modules);
        expect(find.text('Peligros y riesgos'), findsNothing);
        expect(find.text('Ver los 11 módulos'), findsNothing);
        expect(find.text('Gestión de Cuentas'), findsOneWidget);

        await tester.ensureVisible(find.text(modules.last));
        await tester.tap(find.text(modules.last));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.widget<DashboardNavTile>(management).selected, isTrue);
        await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.ensureVisible(organization);
        await tester.tap(organization);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Gestión de Cuentas'), findsNothing);
        expect(find.text('Gestión de Empresas'), findsNothing);
        expect(tester.widget<DashboardNavTile>(organization).expanded, isFalse);

        if (size.width < 1100) {
          await tester.tap(organization);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
          scaffold.closeDrawer();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          scaffold.openDrawer();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            tester.widget<DashboardNavTile>(organization).expanded,
            isTrue,
          );
          expect(find.text('Gestión de Empresas'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
