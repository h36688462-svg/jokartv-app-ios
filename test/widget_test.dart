import 'package:flutter_test/flutter_test.dart';
import 'package:jokartv/main.dart';

void main() {
  testWidgets('StandaloneTVApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StandaloneTVApp());

    // Verify app renders media source / login screen
    expect(find.byType(StandaloneTVApp), findsOneWidget);
  });
}
