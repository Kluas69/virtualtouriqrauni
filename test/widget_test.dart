import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/main.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/core/state/app_state_manager.dart';

void main() {
  group('Virtual Tour App Tests', () {
    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => AppStateManager()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('IQRA Virtual Tour'),
              ),
            ),
          ),
        ),
      );

      // Verify the app title appears
      expect(find.text('IQRA Virtual Tour'), findsOneWidget);
    });

    testWidgets('Theme provider works', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                theme: provider.theme,
                home: const Scaffold(
                  body: Text('Theme Test'),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Theme Test'), findsOneWidget);
    });

    testWidgets('App state manager initializes', (WidgetTester tester) async {
      final appStateManager = AppStateManager();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appStateManager,
          child: const MaterialApp(
            home: Scaffold(
              body: Text('State Test'),
            ),
          ),
        ),
      );

      expect(find.text('State Test'), findsOneWidget);
    });
  });
}