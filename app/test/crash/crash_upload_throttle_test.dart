import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_upload_throttle.dart';
import 'package:amiro_app/crash/crash_upload_throttle_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('30 concurrent reserves allow at most maxPerSession', () async {
    final throttle = CrashUploadThrottle(maxPerSession: 5, maxPerDay: 100);
    var reserved = 0;
    await Future.wait(
      List.generate(30, (i) async {
        if (throttle.tryReserveUploadSlot('fp-$i')) {
          reserved += 1;
        }
      }),
    );
    expect(reserved, 5);
  });

  test('30 sequential reserves allow at most maxPerSession', () {
    final throttle = CrashUploadThrottle(maxPerSession: 5, maxPerDay: 100);
    var reserved = 0;
    for (var i = 0; i < 30; i++) {
      if (throttle.tryReserveUploadSlot('fp-$i')) {
        reserved += 1;
      }
    }
    expect(reserved, 5);
  });

  test('persisted daily cap survives a new throttle instance', () {
    final dir = Directory.systemTemp.createTempSync('amiro-throttle-');
    final store = CrashUploadThrottleStore.inDirectory(dir);
    DateTime fixedClock() => DateTime.utc(2026, 11, 18);
    final first = CrashUploadThrottle(
      maxPerSession: 100,
      maxPerDay: 3,
      store: store,
      clock: fixedClock,
    );
    expect(first.tryReserveUploadSlot('a'), isTrue);
    expect(first.tryReserveUploadSlot('b'), isTrue);
    expect(first.tryReserveUploadSlot('c'), isTrue);
    expect(first.tryReserveUploadSlot('d'), isFalse);

    final second = CrashUploadThrottle(
      maxPerSession: 100,
      maxPerDay: 3,
      store: store,
      clock: fixedClock,
    );
    expect(second.tryReserveUploadSlot('e'), isFalse);
    dir.deleteSync(recursive: true);
  });

  test('persisted store file records daily attempts', () {
    final dir = Directory.systemTemp.createTempSync('amiro-throttle-');
    final store = CrashUploadThrottleStore.inDirectory(dir);
    final throttle = CrashUploadThrottle(
      maxPerSession: 5,
      maxPerDay: 20,
      store: store,
      clock: () => DateTime.utc(2026, 11, 18),
    );
    throttle.tryReserveUploadSlot('one');
    final raw = jsonDecode(
      File('${dir.path}/crash_upload_throttle_state.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(raw['dailyCount'], 1);
    dir.deleteSync(recursive: true);
  });
}