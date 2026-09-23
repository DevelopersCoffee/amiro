import 'package:flutter/services.dart';

/// Makes this device emulate an NFC tag carrying [uri] so another device
/// can tap-and-read it. Android-only — see the design spec §2 for why iOS
/// cannot do this for a general-purpose sharing use case.
abstract class NfcEmulator {
  bool get canEmulate;
  Future<void> writeIdentityPayload(String uri);
  Future<void> stopEmulating();
}

/// The platform channel name shared with Task 4's native Android
/// `HostApduService`. Exposed (rather than kept private) so tests can bind
/// a mock handler to exactly this channel and catch drift between the two
/// sides without needing a device.
const kNfcHceChannelName = 'amiro/nfc_hce';

/// Real emulator, backed by a custom Android `HostApduService` (see
/// `packages/nfc/android/` and Task 4). End-to-end behavior against the
/// native side isn't unit-testable without a device — that's exercised in
/// the Task 4 device spike — but the channel name and the method/argument
/// shape this class sends are locked down in `test/nfc_emulator_test.dart`
/// via a mocked [MethodChannel], so a drift here fails fast instead of
/// silently breaking the native side.
class AndroidNfcEmulator implements NfcEmulator {
  static const _channel = MethodChannel(kNfcHceChannelName);

  @override
  bool get canEmulate => true;

  @override
  Future<void> writeIdentityPayload(String uri) async {
    await _channel.invokeMethod('writeIdentityPayload', {'uri': uri});
  }

  @override
  Future<void> stopEmulating() async {
    await _channel.invokeMethod('stopEmulating');
  }
}

/// No-op emulator for platforms that can't emulate (iOS). Callers should
/// still gate emulate-only UI behind `canEmulate`, but this makes it safe
/// to call the methods unconditionally too.
class NoopNfcEmulator implements NfcEmulator {
  @override
  bool get canEmulate => false;

  @override
  Future<void> writeIdentityPayload(String uri) async {}

  @override
  Future<void> stopEmulating() async {}
}
