import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ultron_mobile/main.dart';

void main() {
  testWidgets('ULTRON Mobile dashboard renders operating modes and call action',
      (tester) async {
    await tester.pumpWidget(const UltronMobileApp());
    expect(find.text('ULTRON'), findsOneWidget);
    expect(find.text('Companion'), findsOneWidget);
    expect(find.text('Independent'), findsOneWidget);
    expect(find.text('CALL ULTRON'), findsOneWidget);
  });
}
