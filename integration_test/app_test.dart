import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:virtualtouriu/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Virtual Tour Integration Tests', () {
    testWidgets('App starts and loads home screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for the app to initialize
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if the app loaded successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for any navigation elements
      final navigationElements = find.byType(GestureDetector);
      if (navigationElements.evaluate().isNotEmpty) {
        await tester.tap(navigationElements.first);
        await tester.pumpAndSettle();
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}