import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc/nfc.dart';

void main() {
  test('NoopNfcEmulator reports canEmulate false and no-ops writes', () async {
    final emulator = NoopNfcEmulator();

    expect(emulator.canEmulate, isFalse);

    // Should complete without throwing — callers on iOS call this
    // unconditionally guarded by `canEmulate`, but the no-op itself must
    // still be safe to call.
    await emulator.writeIdentityPayload('amiro://share?d=abc');
    await emulator.stopEmulating();
  });

  group('AndroidNfcEmulator method channel', () {
    // Locks down the channel name and the method/argument shape Task 4's
    // native `HostApduService` must answer, using a mocked binary
    // messenger — no device needed. See design spec §8: same
    // seam-and-fake pattern as `ThermionFilamentSurface`, applied to a
    // platform channel instead of a platform view.
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel(kNfcHceChannelName);
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    test('canEmulate is true', () {
      expect(AndroidNfcEmulator().canEmulate, isTrue);
    });

    test('the channel name matches the literal Task 4 expects', () {
      expect(kNfcHceChannelName, 'amiro/nfc_hce');
      expect(channel.name, 'amiro/nfc_hce');
    });

    test('writeIdentityPayload invokes "writeIdentityPayload" with {"uri": uri}', () async {
      final emulator = AndroidNfcEmulator();

      await emulator.writeIdentityPayload('amiro://share?d=abc');

      expect(calls, hasLength(1));
      expect(calls.single.method, 'writeIdentityPayload');
      expect(calls.single.arguments, {'uri': 'amiro://share?d=abc'});
    });

    test('stopEmulating invokes "stopEmulating" with no arguments', () async {
      final emulator = AndroidNfcEmulator();

      await emulator.stopEmulating();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'stopEmulating');
      expect(calls.single.arguments, isNull);
    });
  });
}
