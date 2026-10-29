import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/main.dart';

void main() {
  testWidgets('scaffold shows the placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const NewProjectApp());
    expect(find.text('Project ready'), findsOneWidget);
  });
}
