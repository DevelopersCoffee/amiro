import 'package:flutter/services.dart';

/// Makes this device emulate an NFC tag carrying [uri] so another device
/// can tap-and-read it. Android-only — see the design spec §2 for why iOS
/// cannot do this for a general-purpose sharing use case.
abstract class NfcEmulator {
  bool get canEmulate;
  Future<void> writeIdentityPayload(String uri);
  Future<void> stopEmulating();
}

const _kChannelName = 'amiro/nfc_hce';

/// Real emulator, backed by a custom Android `HostApduService` (see
/// `packages/nfc/android/` and Task 4). Talking to the native side isn't
/// unit-testable without a device — the platform channel call itself is
/// exercised in the Task 4 device spike, not here.
class AndroidNfcEmulator implements NfcEmulator {
  static const _channel = MethodChannel(_kChannelName);

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
