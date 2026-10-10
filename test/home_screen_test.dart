import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_explorer/screens/home_screen.dart';

void main() {
  var online = true;
  final client = MockClient((request) async {
    // Respond a frame or two later, like a real request would.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!online) throw http.ClientException('offline');
    if (request.url.path.endsWith('categories.php')) {
      return http.Response('{"categories": [{"strCategory": "Beef"}]}', 200);
    }
    return http.Response(
        '{"meals": [{"idMeal": "1", "strMeal": "Stew"}]}', 200);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await http.runWithClient(
      () => tester.pumpWidget(const MaterialApp(home: HomeScreen())),
      () => client,
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('pull to refresh while offline shows the retry view',
      (tester) async {
    online = true;
    await pumpHome(tester);
    expect(find.text('Stew'), findsOneWidget);

    online = false;
    await tester.fling(find.byType(GridView), const Offset(0, 300), 1000);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Try again'), findsOneWidget);
  });
}
