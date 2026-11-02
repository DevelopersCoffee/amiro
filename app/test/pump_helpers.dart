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

Future<bool> _avatarLoadChainIdleNow(WidgetTester tester) async {
  var idle = false;
  await tester.runAsync(() async {
    try {
      await waitForAvatarLoadIdle().timeout(const Duration(milliseconds: 25));
      idle = true;
    } on TimeoutException {
      idle = false;
    }
  });
  return idle;
}

/// Waits for [_avatarLoadChain] while pumping — never await [waitForAvatarLoadIdle]
/// alone (deadlocks without [tester.pump]).
Future<void> pumpUntilAvatarLoadIdle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (await _avatarLoadChainIdleNow(tester)) {
      await tester.pump(step);
      if (await _avatarLoadChainIdleNow(tester)) {
        await tester.pump(const Duration(milliseconds: 100));
        return;
      }
    }
    await tester.pump(step);
  }
  fail('pumpUntilAvatarLoadIdle timed out waiting for avatar load chain');
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

/// Tall enough that the store [ListView.separated] builds every [storeRowCount]
/// row (avatar stage + app bar + one card height estimate per row).
void useStoreListViewport(WidgetTester tester, {required int storeRowCount}) {
  const avatarStage = 280.0;
  const appBar = kToolbarHeight;
  const listPadding = 16.0;
  const separator = 8.0;
  const cardHeight = 120.0;
  final listHeight =
      listPadding * 2 +
      storeRowCount * cardHeight +
      (storeRowCount > 0 ? (storeRowCount - 1) * separator : 0);
  final height = avatarStage + appBar + listHeight + 64;
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
