import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/di/injection_container.dart' as di;
import 'package:flutter_application_1/main.dart' show EpiDiagnostixMayabApp;

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await di.init();
  });

  testWidgets('App launches and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EpiDiagnostixMayabApp(startWithDashboard: false));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('EpiDiagnostix-Mayab'), findsWidgets);
  });
}
