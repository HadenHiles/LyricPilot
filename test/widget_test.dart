import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lyric_pilot/app/app.dart';

void main() {
  testWidgets('App launches and shows LyricPilot title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LyricPilotApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('LyricPilot'), findsOneWidget);
  });
}
