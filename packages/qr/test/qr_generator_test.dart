import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amiro_qr/amiro_qr.dart';

void main() {
  testWidgets('buildQrWidget renders a QrImageView for the given data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc'))),
    );

    expect(find.byType(buildQrWidget('amiro://share?d=abc').runtimeType), findsWidgets);
  });

  testWidgets('buildQrWidget respects the size parameter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc', size: 100))),
    );
    await tester.pumpAndSettle();

    final sizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'QrImageView'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(sizedBox.width, 100);
    expect(sizedBox.height, 100);
  });
}
