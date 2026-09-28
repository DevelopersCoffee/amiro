import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amiro_qr/amiro_qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  testWidgets('renders dark modules on a cream card with rounded finder eyes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc'))),
    );

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, const Color(0xFFEDE8DE));
    expect(qr.eyeStyle.eyeShape, QrEyeShape.circle);
    expect(qr.eyeStyle.color, const Color(0xFF161510));
    expect(qr.dataModuleStyle.color, const Color(0xFF161510));
  });

  testWidgets('frames the code in a brass-bordered rounded card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc'))),
    );

    final card = tester.widget<Container>(find.byKey(const Key('qrCard')));
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFEDE8DE));
    expect(decoration.borderRadius, BorderRadius.circular(20));
    expect((decoration.border! as Border).top.color, const Color(0xFFC08A3E));
  });
}
