import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/branding/dc_motion.dart';
import 'package:amiro_app/branding/dc_splash.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

Widget _host(VoidCallback onDone, {bool reduced = false}) => MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: DcSplash(onDone: onDone)),
      ),
    );

void main() {
  testWidgets('calls onDone once after the full duration', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(() => done++));
    await tester.pump(DcMotion.total - const Duration(milliseconds: 100));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('tap skips, and onDone still fires only once', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(() => done++));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(DcSplash));
    expect(done, 1);
    await tester.pump(DcMotion.total);
    expect(done, 1);
  });

  testWidgets('reduced motion shows the wordmark statically then hands off',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(() => done++, reduced: true));
    expect(find.text('Developers Coffee'), findsOneWidget);
    expect(done, 0);
    await tester.pump(DcMotion.reducedHold + const Duration(milliseconds: 50));
    expect(done, 1);
  });
}
