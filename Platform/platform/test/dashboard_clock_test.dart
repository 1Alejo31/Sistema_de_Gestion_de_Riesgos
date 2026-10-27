import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/widgets/dashboard_clock.dart';

void main() {
  testWidgets('Home clock shows the current local date and time', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DashboardClock())),
    );

    final now = DateTime.now();
    expect(
      find.textContaining(RegExp('^${now.day} de .+ de ${now.year}\$')),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}:\d{2}$')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
