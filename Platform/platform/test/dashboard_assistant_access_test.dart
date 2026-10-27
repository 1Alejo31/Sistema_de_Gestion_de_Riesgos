import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/views/home_page.dart';
import 'package:landing_page/widgets/dashboard_assistant_access.dart';
import 'package:landing_page/widgets/dashboard_assistant_panel.dart';
import 'package:landing_page/providers/auth_providers.dart';

import 'support/auth_fixtures.dart';

void main() {
  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Home opens assistant, preserves approval, and closes with back',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final auth = createAuth();
      addTearDown(auth.dispose);
      await auth.login('persona@example.com', 'example-password');
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
      expect(find.byType(DashboardAssistantLauncher), findsOneWidget);
      final position = tester.getCenter(
        find.byType(DashboardAssistantLauncher),
      );
      expect(position.dx, greaterThan(195));
      expect(position.dy, greaterThan(700));

      await tester.tap(find.byTooltip('Abrir asesora de IA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SST · Asesora IA'), findsOneWidget);
      await tester.ensureVisible(find.text('Intervenir riesgo crítico'));
      await tester.tap(find.text('Intervenir riesgo crítico'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Aprobada'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar asesora de IA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SST · Asesora IA'), findsNothing);
      await tester.tap(find.byTooltip('Abrir asesora de IA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Aprobada'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SST · Asesora IA'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [const Size(320, 480), const Size(844, 390)]) {
    testWidgets('Assistant scrolls and actions remain reachable at $size', (
      tester,
    ) async {
      viewport(tester, size);
      final scaffoldKey = GlobalKey<ScaffoldState>();
      var reviewed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            endDrawer: DashboardAssistantDrawer(
              child: DashboardAssistantPanel(
                scheduled: const {},
                approved: const {},
                onOpenSuggestion: (_) {},
                onReviewProposals: () => reviewed = true,
              ),
            ),
          ),
        ),
      );
      scaffoldKey.currentState!.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('Revisar propuestas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Revisar propuestas'));
      expect(reviewed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar asesora de IA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(scaffoldKey.currentState!.isEndDrawerOpen, isFalse);
    });
  }

  testWidgets('Launcher respects reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            floatingActionButton: DashboardAssistantLauncher(onPressed: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
