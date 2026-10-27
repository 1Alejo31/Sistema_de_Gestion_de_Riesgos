import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:landing_page/main.dart';
import 'package:landing_page/views/company_information_page.dart';
import 'package:landing_page/widgets/dashboard_header.dart';
import 'package:landing_page/widgets/dashboard_widgets.dart';

import 'support/auth_fixtures.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> fill(WidgetTester tester, String key, String value) async {
    final field = find.byKey(Key('company_$key'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await settle(tester);
  }

  Future<void> tab(WidgetTester tester, int index) =>
      tap(tester, find.byKey(Key('company_tab_$index')));
  Future<void> confirm(WidgetTester tester) async {
    expect(find.byKey(const Key('operation_success_confirm')), findsOneWidget);
    await tap(tester, find.byKey(const Key('operation_success_confirm')));
  }

  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets(
      'company information retains shell and submits scoped forms at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final writes = <http.Request>[];
        final lists = <String, List<Map<String, dynamic>>>{
          'work-sites': [],
          'processes': [],
          'areas': [],
          'third-parties': [],
          'memberships': [],
        };
        final auth = createAuth(
          handler: (request) async {
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
                ],
              }, 200);
            }
            if (request.url.path.startsWith('/api/v1/organizations/org-')) {
              final resource = request.url.path.split('/').last;
              if (request.method != 'GET') {
                writes.add(request);
                expect(
                  request.headers['Authorization'],
                  'Bearer opaque-access-one',
                );
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                final result = {
                  'id': '$resource-created',
                  'organizationId': 'org-1',
                  'status': resource == 'company-profile' ? 'DRAFT' : 'ACTIVE',
                  'version': 1,
                  ...body,
                };
                if (resource == 'memberships') {
                  return jsonResponse({
                    'data': {
                      'id': 'user-1',
                      'email': body['email'],
                      'organizationId': 'org-1',
                      'membership': {
                        'role': body['role'],
                        'scope': body['scope'],
                        'status': 'ACTIVE',
                      },
                    },
                  }, 201);
                }
                if (lists.containsKey(resource)) lists[resource]!.add(result);
                return jsonResponse({
                  'data': result,
                }, request.method == 'POST' ? 201 : 200);
              }
              if (resource == 'company-profile') {
                return jsonResponse({
                  'data': {
                    'organizationId': 'org-1',
                    'status': 'NOT_STARTED',
                    'commercialName': null,
                    'economicActivities': [],
                    'contact': {},
                    'version': null,
                  },
                }, 200);
              }
              if (resource == 'workforce-distribution') {
                return jsonResponse({
                  'data': {
                    'organizationId': 'org-1',
                    'entries': [],
                    'version': null,
                  },
                }, 200);
              }
              if (resource == 'information-findings') {
                return jsonResponse({
                  'data': {
                    'organizationId': 'org-1',
                    'checkedAt': '2026-10-14T12:00:00Z',
                    'counts': {},
                    'findings': [
                      {
                        'code': 'MISSING',
                        'section': 'profile',
                        'message': 'Revisa la información declarada.',
                      },
                    ],
                  },
                }, 200);
              }
              return jsonResponse({'data': lists[resource] ?? []}, 200);
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
              initialRoute: size.width > 1100
                  ? '/home'
                  : '/company-information',
              theme: ThemeData(),
            ),
          ),
        );
        await settle(tester);
        if (size.width > 1100) {
          await tap(
            tester,
            find.widgetWithText(DashboardNavTile, 'Gestión SG-SST'),
          );
          await tap(tester, find.text('1. Información general de la empresa'));
        }
        expect(find.byType(CompanyInformationPage), findsOneWidget);
        expect(find.byType(DashboardCompanyHeader), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DashboardCompanyHeader),
            matching: find.byType(TextField),
          ),
          findsNothing,
        );
        expect(find.byTooltip('Notificaciones'), findsNothing);
        expect(find.text('Aquí tienes el panorama en SST'), findsNothing);
        expect(
          find.text('ELIGE LA EMPRESA CON LA QUE VAS A TRABAJAR'),
          findsOneWidget,
        );
        final selector = find.descendant(
          of: find.byType(CompanyInformationPage),
          matching: find.byKey(const Key('organization_selector')),
        );
        await tap(tester, selector);
        await tester.enterText(
          find.byKey(const Key('organization_picker_search')),
          'Empresa 1',
        );
        await settle(tester);
        await tap(tester, find.byType(ListTile));
        expect(selector, findsNothing);
        expect(find.byKey(const Key('company_context_card')), findsOneWidget);
        expect(find.byKey(const Key('company_folder')), findsOneWidget);
        expect(find.text('NIT 900123451-7'), findsOneWidget);
        expect(find.byKey(const Key('company_tab_8')), findsOneWidget);

        await tab(tester, 2);
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Guardar datos generales'),
        );
        expect(writes, isEmpty);
        await fill(tester, 'commercialName', 'Mi empresa');
        await fill(tester, 'activity_code_0', '1234');
        await fill(tester, 'activity_description_0', 'Actividad declarada');
        await fill(tester, 'email', 'correo inválido');
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Guardar datos generales'),
        );
        expect(writes, isEmpty);
        await fill(tester, 'email', 'empresa@example.com');
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Guardar datos generales'),
        );
        await confirm(tester);
        final profile = jsonDecode(writes.last.body);
        expect(writes.last.method, 'PUT');
        expect(profile['economicActivities'].single['isPrimary'], true);
        expect(profile['contact']['email'], 'empresa@example.com');
        // Drafts stay in place when switching sections.
        await tab(tester, 1);
        await tab(tester, 2);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('company_commercialName')),
              )
              .controller!
              .text,
          'Mi empresa',
        );

        await tab(tester, 3);
        await fill(tester, 'siteName', 'Sede central');
        await fill(tester, 'municipality', 'Bogotá');
        await fill(tester, 'address', 'Carrera 1 # 2-3');
        await tap(tester, find.widgetWithText(FilledButton, 'Registrar sede'));
        await confirm(tester);
        expect(
          writes.last.headers['Idempotency-Key']!.length,
          inInclusiveRange(8, 128),
        );
        expect(jsonDecode(writes.last.body)['type'], 'HEADQUARTERS');

        await tab(tester, 4);
        await fill(tester, 'processName', 'Compras');
        await fill(tester, 'mainActivities', 'Compras, Inventario');
        await tap(tester, find.widgetWithText(FilledButton, 'Crear proceso'));
        await confirm(tester);
        expect(jsonDecode(writes.last.body)['mainActivities'], [
          'Compras',
          'Inventario',
        ]);
        await fill(tester, 'areaName', 'Administración');
        await tap(tester, find.widgetWithText(CheckboxListTile, 'Compras'));
        await tap(
          tester,
          find.widgetWithText(CheckboxListTile, 'Sede central'),
        );
        await tap(tester, find.widgetWithText(FilledButton, 'Crear área'));
        await confirm(tester);
        expect(jsonDecode(writes.last.body)['processIds'], [
          'processes-created',
        ]);
        expect(jsonDecode(writes.last.body)['workSiteIds'], [
          'work-sites-created',
        ]);

        await tab(tester, 5);
        for (final entry in {
          'relationshipType': 'Directa',
          'jobTitle': 'Operarios',
          'shift': 'Diurno',
          'workSchedule': 'Completa',
          'workerCount': '12',
        }.entries) {
          await fill(tester, entry.key, entry.value);
        }
        await tap(tester, find.widgetWithText(OutlinedButton, 'Agregar grupo'));
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Guardar caracterización'),
        );
        await confirm(tester);
        expect(
          jsonDecode(writes.last.body)['entries'].single['workerCount'],
          12,
        );

        await tab(tester, 6);
        await fill(tester, 'legalName', 'Proveedor S.A.S.');
        await fill(tester, 'taxIdentifier', '900123456-7');
        await fill(tester, 'thirdDescription', 'Suministro de equipos');
        await tap(tester, find.widgetWithText(FilterChip, 'Proveedor'));
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Registrar empresa'),
        );
        await confirm(tester);
        expect(jsonDecode(writes.last.body)['relationshipTypes'], ['SUPPLIER']);

        await tab(tester, 7);
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Consultar hallazgos actuales'),
        );
        expect(find.text('Revisa la información declarada.'), findsOneWidget);
        await tab(tester, 8);
        await fill(tester, 'memberEmail', 'cuenta@example.com');
        await tap(tester, find.byKey(const Key('company_memberRole')));
        await tester.enterText(
          find.byKey(const Key('company_memberRole_search')),
          'trabajador',
        );
        await settle(tester);
        await tap(
          tester,
          find.byKey(const ValueKey('company_memberRole_WORKER')),
        );
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'Vincular y habilitar acceso'),
        );
        await confirm(tester);
        expect(jsonDecode(writes.last.body)['scope'], {'type': 'ORGANIZATION'});

        // Switching company discards the previous company's form state.
        await tap(tester, find.byKey(const Key('company_change_organization')));
        await tester.enterText(
          find.byKey(const Key('organization_picker_search')),
          'Empresa 2',
        );
        await settle(tester);
        await tap(tester, find.byType(ListTile));
        expect(
          find.text('Una visión clara de tu organización'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('company_memberEmail')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
