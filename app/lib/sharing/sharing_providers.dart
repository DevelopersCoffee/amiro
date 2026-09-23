import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sharing/sharing.dart';
import 'package:nfc/nfc.dart';

/// Emits a [SharedProfile] whenever the app is opened via an `amiro://`
/// link — whether cold-launched from it or already running and receiving
/// it via the platform's runtime link delivery. Emits `null` if a link
/// arrives that isn't a valid Amiro share link (so listeners can
/// distinguish "no link yet" from "got something, but it wasn't ours" if
/// needed — though `parseShareUri` returning `null` is the more common
/// path here).
final incomingShareLinkProvider = StreamProvider<SharedProfile?>((ref) {
  final appLinks = AppLinks();
  return appLinks.uriLinkStream.map((uri) => parseShareUri(uri.toString()));
});

/// Overridden in `main.dart` with `AndroidNfcEmulator()` or
/// `NoopNfcEmulator()` based on the real platform; overridden in tests
/// with a fake.
final nfcEmulatorProvider = Provider<NfcEmulator>((ref) {
  throw UnimplementedError('nfcEmulatorProvider must be overridden');
});

/// Overridden in `main.dart` with a real `ManagerNfcReader()` — reading a
/// tag (unlike emulating one) works on both Android (`nfc_manager`'s
/// Android backend) and iOS (Core NFC), so unlike `nfcEmulatorProvider`
/// this isn't platform-gated. Overridden in tests with a fake `NfcReader`.
final nfcReaderProvider = Provider<NfcReader>((ref) {
  throw UnimplementedError('nfcReaderProvider must be overridden');
});

/// Whether this device is currently emulating an NFC tag to *send* its own
/// identity (`share_screen.dart`'s "Start NFC sharing" toggle). Starting a
/// reader session while this is true would fight the emulator for the same
/// NFC radio mode: on Android, `NfcManager.instance.startSession` (reader
/// mode) disables the device's own HCE card emulation for as long as it's
/// active; on iOS it would pop the system "Ready to Scan" sheet in the
/// middle of a send. [incomingNfcShareProvider] watches this to pause
/// reading while it's true. Set by `ShareScreen`, read here — this is the
/// one piece of shared state coordinating the two NFC roles.
final nfcEmulatingProvider = StateProvider<bool>((ref) => false);

/// Emits a [SharedProfile] whenever [nfcReaderProvider]'s reader picks up
/// an incoming NFC tag — a physical Type 4 Tag or another Amiro device
/// emulating one via HCE — whose decoded text payload parses as a valid
/// `amiro://share` link. Emits `null` for a tag read that isn't one of
/// ours, mirroring [incomingShareLinkProvider]'s contract.
///
/// Does not read while [nfcEmulatingProvider] is true (see its doc) —
/// rebuilding on that flag flipping back to `false` disposes this
/// provider's previous build (stopping the reader via the `onDispose`
/// below, if it was reading) and starts a fresh read the next time it's
/// watched while not emulating.
final incomingNfcShareProvider = StreamProvider<SharedProfile?>((ref) {
  final isEmulating = ref.watch(nfcEmulatingProvider);
  final reader = ref.watch(nfcReaderProvider);

  if (isEmulating) {
    return const Stream<SharedProfile?>.empty();
  }

  ref.onDispose(() {
    // Best-effort: `stop()` is async but provider disposal is
    // synchronous, so this fires the stop without awaiting it.
    reader.stop();
  });
  return reader.readIncomingPayload().map(parseShareUri);
});
