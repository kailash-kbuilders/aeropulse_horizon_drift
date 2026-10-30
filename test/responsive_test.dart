import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cravecart/main.dart';

/// Screen sizes covering small phones, tall phones, tablets and landscape.
const List<Size> kSizes = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(390, 844),
  Size(412, 915),
  Size(480, 800),
  Size(600, 960),
  Size(768, 1024),
  Size(1024, 768),
  Size(1280, 800),
];

const List<double> kTextScales = <double>[1.0, 1.3, 2.0];

Future<void> _pump(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  await tester.pumpWidget(const CraveCartApp());
  await tester.pumpAndSettle();
}

void main() {
  for (final Size size in kSizes) {
    for (final double scale in kTextScales) {
      testWidgets(
        'home and detail stay clean at ${size.width.toInt()}x'
        '${size.height.toInt()} @${scale}x',
        (WidgetTester tester) async {
          await _pump(tester, size, scale);
          expect(tester.takeException(), isNull, reason: 'home first frame');

          // Walk the whole home list.
          final Finder list = find.byType(ListView).first;
          await tester.drag(list, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'home scrolled');
          await tester.drag(list, const Offset(0, 600));
          await tester.pumpAndSettle();

          // Every bottom tab.
          for (final String label in <String>[
            'Offers',
            'Orders',
            'Favorite',
            'Home'
          ]) {
            await tester.tap(find.text(label).last, warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'tab $label');
          }

          // Open the dish detail and scroll it end to end.
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Spicy Chicken Burger').first,
              warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'detail first frame');

          await tester.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'detail scrolled');

          // Tap every control on the detail screen.
          await tester.tap(find.text('Large'), warnIfMissed: false);
          await tester.pumpAndSettle();
          await tester.tap(find.text('X Large'), warnIfMissed: false);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.add_rounded).last,
              warnIfMissed: false);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add to Cart'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'detail interactions');
        },
      );
    }
  }
}
