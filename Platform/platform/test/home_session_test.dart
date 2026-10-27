import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/providers/auth_providers.dart';
import 'package:landing_page/views/home_page.dart';
import 'package:landing_page/widgets/dashboard_header.dart';

import 'support/auth_fixtures.dart';

void main() {
  for (final initiallyAuthenticated in [false, true]) {
    testWidgets(
      'Home handles missing identity, authenticated=$initiallyAuthenticated',
      (tester) async {
        var organizationRequests = 0;
        final auth = createAuth(
          handler: (request) async {
            if (request.url.path == '/api/v1/organizations') {
              organizationRequests++;
            }
            return defaultHandler(request);
          },
        );
        if (initiallyAuthenticated) {
          await auth.login('persona@example.com', 'password');
        }
        await tester.pumpWidget(
          AuthTestHost(
            auth: auth,
            child: ProviderScope(
              overrides: [authControllerProvider.overrideWithValue(auth)],
              child: const MaterialApp(home: HomePage()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        if (initiallyAuthenticated) {
          expect(find.byType(DashboardHeader), findsOneWidget);
          expect(find.text('Últimos 30 días'), findsNothing);
          expect(find.text('Abril 2024'), findsNothing);
          expect(find.text('1 abr. – 30 abr. 2024'), findsNothing);
          await auth.logout();
          await tester.pumpAndSettle();
        } else {
          expect(organizationRequests, 0);
        }
        expect(find.byType(DashboardHeader), findsNothing);
        expect(find.text('Volviendo al inicio de sesión…'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
