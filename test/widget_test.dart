// This is a basic Flutter widget test for the Virtual Tour app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:virtualtouriu/main.dart';

void main() {
  testWidgets('App instantiates without platform import errors', (WidgetTester tester) async {
    // This test verifies that the app can be created without dart:html import errors
    // which was the main issue we were fixing with platform abstraction
    
    // Build our app - this will fail if there are platform-specific import issues
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads without throwing platform import errors
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // If we get here, the platform abstraction is working correctly
    // and there are no more dart:html import errors on non-web platforms
  });
}
