import 'dart:io';

import 'package:amiro_app/crash/crash_upload_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to off when missing or invalid file', () async {
    final dir = await Directory.systemTemp.createTemp('amiro-crash-prefs');
    final prefs = CrashUploadPreferences.inDirectory(dir);
    expect(await prefs.isEnabled(), isFalse);

    await File('${dir.path}/crash_upload_opt_in.json').writeAsString('not-json');
    expect(await prefs.isEnabled(), isFalse);

    await dir.delete(recursive: true);
  });

  test('inMemory toggles upload consent', () async {
    final prefs = CrashUploadPreferences.inMemory();
    expect(await prefs.isEnabled(), isFalse);
    await prefs.setEnabled(true);
    expect(await prefs.isEnabled(), isTrue);
    await prefs.setEnabled(false);
    expect(await prefs.isEnabled(), isFalse);
  });

  test('inDirectory persists enabled across a new instance', () async {
    final dir = await Directory.systemTemp.createTemp('amiro-crash-prefs-rt');
    final first = CrashUploadPreferences.inDirectory(dir);
    await first.setEnabled(true);
    final second = CrashUploadPreferences.inDirectory(dir);
    expect(await second.isEnabled(), isTrue);
    await dir.delete(recursive: true);
  });
}