import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmershub_gh/src/app_v4.dart';
import 'package:farmershub_gh/main.dart';

void main() {
  testWidgets('Login validates empty credentials before contacting Firebase',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Enter your email and password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Farm registration explains invalid acreage', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddFarmPage()));
    await tester.tap(find.text('Save Farm'));
    await tester.pump();
    expect(
        find.text(
            'Enter a farm name, location and valid acreage greater than zero.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Startup failure remains visible rather than leaving a blank screen',
      (tester) async {
    await tester.pumpWidget(
        const StartupFailureApp(error: 'test configuration failure'));
    expect(find.text('FarmersHub could not start'), findsOneWidget);
    expect(find.textContaining('test configuration failure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
