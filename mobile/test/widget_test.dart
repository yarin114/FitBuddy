import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbuddy/main.dart';

void main() {
  testWidgets('App smoke test — FitBuddyApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FitBuddyApp()),
    );
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
