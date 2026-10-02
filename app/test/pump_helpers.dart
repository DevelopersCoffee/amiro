import 'dart:async';

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

/// Waits for [_avatarLoadChain] while pumping — never await [waitForAvatarLoadIdle]
/// alone (deadlocks without [tester.pump]).
///
/// Also avoids a false idle when the chain is still [Future.value] from
/// [resetAvatarLoadChainForTest] before the widget schedules [ensureAvatarLoaded].
Future<void> pumpUntilAvatarLoadIdle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 120,
}) async {
  for (var settlePass = 0; settlePass < 8; settlePass++) {
    var chain = waitForAvatarLoadIdle();
    var idle = false;
    unawaited(chain.then((_) => idle = true));

    var pumps = 0;
    while (pumps < maxPumps) {
      if (idle && pumps > 0) break;

      if (idle && pumps == 0) {
        await tester.pump(step);
        pumps++;
        final next = waitForAvatarLoadIdle();
        if (identical(chain, next)) break;
        chain = next;
        idle = false;
        unawaited(chain.then((_) => idle = true));
        continue;
      }

      await tester.pump(step);
      pumps++;
    }

    if (!idle) {
      fail('pumpUntilAvatarLoadIdle timed out waiting for avatar load chain');
    }

    await tester.pump(step);
    final after = waitForAvatarLoadIdle();
    if (identical(chain, after)) {
      await tester.pump(const Duration(milliseconds: 100));
      return;
    }
  }
  fail('pumpUntilAvatarLoadIdle: avatar load chain did not settle');
}

/// After [pumpWidget], wait for in-flight [ensureAvatarLoaded] and a few frames.
Future<void> pumpAfterAvatarLoad(WidgetTester tester) async {
  await tester.pump();
  await pumpUntilAvatarLoadIdle(tester);
}

/// Enough time for the first-launch reveal animation (500ms) to finish.
Future<void> pumpThroughAvatarReveal(WidgetTester tester) async {
  await pumpAfterAvatarLoad(tester);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> pumpShort(WidgetTester tester, {int frames = 5}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
