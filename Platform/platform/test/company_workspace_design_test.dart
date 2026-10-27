import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/widgets/company_workspace_design.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(1200, 900)]) {
    testWidgets(
      'company folder keeps one active title and other sections as buttons at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = 0;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: CompanySectionNavigation(
                      selected: selected,
                      onSelected: (value) => setState(() => selected = value),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        final scroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(CompanySectionNavigation),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.byTooltip('Secciones siguientes'));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, greaterThan(0));
        // The active section occupies the fixed folder title, not another button.
        update(() => selected = 8);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('company_tab_8')), findsNothing);
        expect(find.text('09 / 09'), findsOneWidget);
        expect(find.byKey(const Key('company_active_folder')), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('company_folder_title')))
              .data,
          'Personas y roles',
        );
        final offset = scroll.position.pixels;
        await tester.tap(find.byTooltip('Secciones anteriores'));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, lessThan(offset));
        update(() => selected = 0);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('company_folder_title')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byKey(const Key('company_tab_3')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('company_tab_3')));
        await tester.pumpAndSettle();
        expect(selected, 3);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('company_folder_title')))
              .data,
          'Sedes',
        );
        expect(find.byKey(const Key('company_active_folder')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
