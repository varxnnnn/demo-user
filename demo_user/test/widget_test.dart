import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_user/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify MaterialApp is loaded
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
