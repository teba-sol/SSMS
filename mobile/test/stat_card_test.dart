import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sscs_mobile/core/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard fits in a constrained container without overflowing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 106,
              child: StatCard(
                title: 'Very long title that should wrap neatly',
                value: '1234',
                icon: Icons.bar_chart,
                color: Colors.blue,
                subtitle: 'A long subtitle that must stay visible',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
