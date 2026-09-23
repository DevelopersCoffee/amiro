import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nfc/nfc.dart';

import 'package:amiro_app/sharing/sharing_providers.dart';

/// A fake [NfcReader] that tracks how many times each method is called and
/// lets the test drive `readIncomingPayload()`'s stream directly — stands
/// in for real NFC hardware (see `packages/nfc/lib/src/nfc_reader.dart`),
/// same pattern as `incoming_share_listener_test.dart`'s `_FakeNfcReader`.
class _FakeNfcReader implements NfcReader {
  final _controller = StreamController<String>.broadcast();
  int readCallCount = 0;
  int stopCallCount = 0;

  void emit(String payload) => _controller.add(payload);

  @override
  Stream<String> readIncomingPayload() {
    readCallCount++;
    return _controller.stream;
  }

  @override
  Future<void> stop() async => stopCallCount++;
}

void main() {
  test(
    'incomingNfcShareProvider reads from the NfcReader when not emulating',
    () async {
      final reader = _FakeNfcReader();
      final container = ProviderContainer(
        overrides: [nfcReaderProvider.overrideWithValue(reader)],
      );
      addTearDown(container.dispose);

      container.listen(incomingNfcShareProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      expect(reader.readCallCount, 1);
    },
  );

  test(
    'incomingNfcShareProvider does not read while nfcEmulatingProvider is true',
    () async {
      final reader = _FakeNfcReader();
      final container = ProviderContainer(
        overrides: [nfcReaderProvider.overrideWithValue(reader)],
      );
      addTearDown(container.dispose);

      // Mark this device as actively emulating (sending) *before* anything
      // watches incomingNfcShareProvider, the same way ShareScreen's
      // `_toggleNfcEmulate` flips it ahead of the send starting.
      container.read(nfcEmulatingProvider.notifier).state = true;

      container.listen(incomingNfcShareProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      expect(
        reader.readCallCount,
        0,
        reason:
            'starting a reader session while emulating would disable this '
            "device's own HCE emulation on Android and pop iOS's "
            '"Ready to Scan" sheet mid-send',
      );
    },
  );

  test(
    'flipping nfcEmulatingProvider to true stops an in-progress read, '
    'and flipping it back to false starts a fresh one',
    () async {
      final reader = _FakeNfcReader();
      final container = ProviderContainer(
        overrides: [nfcReaderProvider.overrideWithValue(reader)],
      );
      addTearDown(container.dispose);

      container.listen(incomingNfcShareProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      expect(reader.readCallCount, 1);
      expect(reader.stopCallCount, 0);

      // Start emulating (sending) — the previous read should be torn down.
      container.read(nfcEmulatingProvider.notifier).state = true;
      await Future<void>.delayed(Duration.zero);
      expect(reader.stopCallCount, 1);

      // Stop emulating — reading should resume with a fresh session.
      container.read(nfcEmulatingProvider.notifier).state = false;
      await Future<void>.delayed(Duration.zero);
      expect(reader.readCallCount, 2);
    },
  );
}
