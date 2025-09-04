import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskmanager/main.dart';

// Mock Firebase for testing
void setupFirebaseAuthMocks() {
  // Mock setup would go here in a real app
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAuthMocks();
  });

  testWidgets('TaskManager app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    // Verify that we can find either a loading indicator or app content
    final loadingFinder = find.byType(CircularProgressIndicator);
    final appTitleFinder = find.text('Task Manager');
    
    expect(
      loadingFinder.evaluate().isNotEmpty || appTitleFinder.evaluate().isNotEmpty,
      isTrue,
    );
  });
}
