// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_mitra/main.dart';
import 'package:kisan_mitra/core/localization/locale_provider.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    await tester.pumpWidget(MyApp(localeProvider: localeProvider));
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
// Widget tests are skipped: MyApp now requires Firebase initialization
// and a LocaleProvider argument that cannot be mocked in a simple unit test.
// Use integration tests for full app testing.
