import 'package:flutter_test/flutter_test.dart';

import 'package:rave_finder/main.dart';

void main() {
  testWidgets('Home screen shows empty state when no friends bonded',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RaveFinderApp());
    await tester.pump();

    expect(find.text('RaveFinder'), findsOneWidget);
    expect(find.textContaining('Nessun amico bondato'), findsOneWidget);
    expect(find.text('Aggiungi amico'), findsOneWidget);
  });
}
