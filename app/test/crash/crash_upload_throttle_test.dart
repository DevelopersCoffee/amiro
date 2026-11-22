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

  test('day rollover resets dailyCount and allows new uploads', () {
    var currentTime = DateTime.utc(2026, 11, 18, 12);
    final throttle = CrashUploadThrottle(
      maxPerSession: 100,
      maxPerDay: 2,
      clock: () => currentTime,
    );
    expect(throttle.tryReserveUploadSlot('day1-a'), isTrue);
    expect(throttle.tryReserveUploadSlot('day1-b'), isTrue);
    expect(throttle.tryReserveUploadSlot('day1-c'), isFalse);

    currentTime = DateTime.utc(2026, 11, 19, 0, 1);
    expect(throttle.tryReserveUploadSlot('day2-a'), isTrue);
    expect(throttle.tryReserveUploadSlot('day2-b'), isTrue);
    expect(throttle.tryReserveUploadSlot('day2-c'), isFalse);
  });

  test('corrupt or negative persisted state is handled safely without throwing', () {
    final dir = Directory.systemTemp.createTempSync('amiro-throttle-corrupt-');
    final stateFile = File('${dir.path}/crash_upload_throttle_state.json');
    final store = CrashUploadThrottleStore.inDirectory(dir);

    stateFile.writeAsStringSync('{"dayKey":"2026-11-18","dailyCount":-5}');
    expect(store.loadSync(), (null, 0));

    stateFile.writeAsStringSync('{corrupt json...');
    expect(store.loadSync(), (null, 0));

    stateFile.writeAsStringSync('[1, 2, 3]');
    expect(store.loadSync(), (null, 0));

    stateFile.writeAsStringSync('{"dayKey":123,"dailyCount":"not-a-number"}');
    expect(store.loadSync(), (null, 0));

    final throttle = CrashUploadThrottle(
      maxPerSession: 5,
      maxPerDay: 20,
      store: store,
      clock: () => DateTime.utc(2026, 11, 18),
    );
    expect(throttle.tryReserveUploadSlot('fp-1'), isTrue);

    dir.deleteSync(recursive: true);
  });

  test('saveSync gracefully handles filesystem errors without throwing', () {
    final store = CrashUploadThrottleStore(File('/dev/null/impossible/path.json'));
    expect(() => store.saveSync('2026-11-18', 1), returnsNormally);
  });
}
