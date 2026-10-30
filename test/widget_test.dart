import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cravecart/main.dart';

void main() {
  // The home screen is a tall scroll view, so give the test a phone-sized
  // surface instead of the default 800x600 window.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CraveCartApp());
    await tester.pump();
  }

  testWidgets('home screen shows the greeting and popular section',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Hi, Alex 👋'), findsOneWidget);
    expect(find.text('Popular Now'), findsOneWidget);
    expect(find.text('Search your favorite food'), findsOneWidget);
  });

  testWidgets('tapping a dish opens the detail screen',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Scroll the carousel clear of the floating nav bar, then open a dish.
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spicy Chicken Burger').first);
    await tester.pumpAndSettle();

    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
  });

  testWidgets('quantity and add-ons change the cart total',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spicy Chicken Burger').first);
    await tester.pumpAndSettle();

    // 6.49 base + 0.99 cheese + 1.40 bacon = 8.88
    expect(find.text('\$8.88'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('\$17.76'), findsOneWidget);
  });
}
