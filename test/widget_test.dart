import 'package:flutter_test/flutter_test.dart';

import 'package:yonigames_app/main.dart';

void main() {
  testWidgets('shows the room entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('YoniGames'), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);
    expect(find.text('Join with code'), findsOneWidget);
  });
}
