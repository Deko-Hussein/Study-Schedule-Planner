import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const StudyPlannerApp(),
      ),
    );

    // Verify that the splash screen shows up (it won't have "0" anymore)
    expect(find.text('Study Schedule Planner'), findsWidgets);
  });
}
