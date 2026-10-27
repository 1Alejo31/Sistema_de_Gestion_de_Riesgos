import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/main.dart';
import 'package:landing_page/views/login_page.dart';
import 'package:landing_page/views/about_section.dart';
import 'package:landing_page/controllers/content_repository.dart';

import 'support/auth_fixtures.dart';

void main() {
  testWidgets(
    'public mission section lays out on mobile without misplaced Expanded',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AboutSection(
                content: ContentRepository().getAboutContent(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Nuestra Misión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('app exposes login form instead of the starter counter', (
    tester,
  ) async {
    final auth = createAuth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MyApp(authController: auth, initialRoute: '/login', theme: ThemeData()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
