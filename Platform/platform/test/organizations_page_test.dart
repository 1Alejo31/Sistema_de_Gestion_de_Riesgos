import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/main.dart';
import 'package:landing_page/views/organizations_page.dart';
import 'package:landing_page/widgets/dashboard_header.dart';

import 'support/auth_fixtures.dart';
import 'support/users_fixtures.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets(
    'organization menu opens the workspace and registers with a searchable active admin',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      http.Request? createRequest;
      var organizationListRequests = 0;
      const originalOrganization = {
        '_id': 'organization-1',
        'legalId': '800111222-3',
        'legalName': 'Compañía Inicial S.A.S.',
        'status': 'ACTIVE',
        'createdAt': '2026-10-13T12:00:00.000Z',
      };
      const createdOrganization = {
        '_id': 'organization-2',
        'legalId': '900123456-7',
        'legalName': 'Empresa Ejemplo S.A.S.',
        'status': 'ACTIVE',
        'createdAt': '2026-10-14T12:00:00.000Z',
      };
      final auth = createAuth(
        handler: (request) async {
          if (request.url.path == '/api/v1/users') {
            return usersResponse();
          }
          if (request.url.path == '/api/v1/organizations' &&
              request.method == 'POST') {
            createRequest = request;
            return jsonResponse({'data': createdOrganization}, 201);
          }
          if (request.url.path == '/api/v1/organizations') {
            organizationListRequests++;
            return jsonResponse({
              'data': organizationListRequests == 1
                  ? [originalOrganization]
                  : [originalOrganization, createdOrganization],
            }, 200);
          }
          return defaultHandler(request);
        },
      );
      addTearDown(auth.dispose);
      await auth.login('admin@example.com', 'password');
      await tester.pumpWidget(
        AuthTestHost(
          auth: auth,
          child: MyApp(
            authController: auth,
            initialRoute: '/organizations',
            theme: ThemeData(),
          ),
        ),
      );
      await settle(tester);

      expect(find.byType(OrganizationsPage), findsOneWidget);
      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.byKey(const Key('create_organization_open')), findsOneWidget);
      expect(find.byKey(const Key('organizations_table')), findsOneWidget);
      expect(find.text('Compañía Inicial S.A.S.'), findsOneWidget);
      expect(organizationListRequests, 1);

      await tester.tap(find.byKey(const Key('create_organization_open')));
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('organization_admin_search')),
        'demo.consultant',
      );
      await tester.pump();
      expect(find.text('demo.observer@sgsst.invalid'), findsNothing);
      final administrator = find.byKey(
        const Key('organization_admin_22001202-81c0-4e93-bb7e-75b19da36eff'),
      );
      await tester.ensureVisible(administrator);
      await tester.tap(administrator);
      await tester.enterText(
        find.byKey(const Key('organization_legal_id')),
        '900123456-7',
      );
      await tester.enterText(
        find.byKey(const Key('organization_legal_name')),
        'Empresa Ejemplo S.A.S.',
      );
      await tester.ensureVisible(find.byKey(const Key('organization_submit')));
      await tester.tap(find.byKey(const Key('organization_submit')));
      await settle(tester);

      expect(createRequest?.method, 'POST');
      expect(
        createRequest?.headers['Authorization'],
        'Bearer opaque-access-one',
      );
      expect(jsonDecode(createRequest!.body), {
        'legalId': '900123456-7',
        'legalName': 'Empresa Ejemplo S.A.S.',
        'administratorId': '22001202-81c0-4e93-bb7e-75b19da36eff',
      });
      expect(
        find.byKey(const Key('organization_created_alert')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organization_created_name')),
        findsOneWidget,
      );
      expect(organizationListRequests, 2);
      await tester.tap(find.byKey(const Key('organization_created_confirm')));
      await settle(tester);
      expect(find.text('Empresa Ejemplo S.A.S.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
