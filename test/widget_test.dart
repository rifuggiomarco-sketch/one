import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_earbuds/main.dart';

void main() {
  testWidgets('Home screen shows empty state when no earbuds saved',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FindMyEarbudsApp());
    await tester.pump();

    expect(find.text('Trova i tuoi auricolari'), findsOneWidget);
    expect(find.textContaining('Nessun auricolare salvato'), findsOneWidget);
    expect(find.text('Aggiungi auricolari'), findsOneWidget);
  });
}
