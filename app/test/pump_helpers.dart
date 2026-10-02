import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/avatar/avatar_loader.dart';

/// Pumps with a frame budget until [finder] matches, instead of [pumpAndSettle]
/// (which hangs on infinite animations like [CircularProgressIndicator]).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('pumpUntilFound timed out waiting for $finder');
}

/// After [pumpWidget], wait for in-flight [ensureAvatarLoaded] and a few frames.
Future<void> pumpAfterAvatarLoad(WidgetTester tester) async {
  await tester.pump();
  await waitForAvatarLoadIdle();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Enough time for the first-launch reveal animation (500ms) to finish.
Future<void> pumpThroughAvatarReveal(WidgetTester tester) async {
  await pumpAfterAvatarLoad(tester);
  await tester.pump(const Duration(milliseconds: 600));
}

void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
