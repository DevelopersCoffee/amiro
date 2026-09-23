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
}
