import 'package:flutter_test/flutter_test.dart';

import 'package:outline_manager_app/main.dart';

void main() {
  testWidgets('renders server list title', (WidgetTester tester) async {
    await tester.pumpWidget(const OutlineManagerApp());

    expect(find.text('Outline Mobile Manager'), findsOneWidget);
    expect(find.text('No servers yet. Tap + to add your Outline API URL.'), findsOneWidget);
  });
}
