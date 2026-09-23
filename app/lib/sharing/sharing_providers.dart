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

/// Emits a [SharedProfile] whenever [nfcReaderProvider]'s reader picks up
/// an incoming NFC tag — a physical Type 4 Tag or another Amiro device
/// emulating one via HCE — whose decoded text payload parses as a valid
/// `amiro://share` link. Emits `null` for a tag read that isn't one of
/// ours, mirroring [incomingShareLinkProvider]'s contract.
final incomingNfcShareProvider = StreamProvider<SharedProfile?>((ref) {
  final reader = ref.watch(nfcReaderProvider);
  ref.onDispose(() {
    // Best-effort: `stop()` is async but provider disposal is
    // synchronous, so this fires the stop without awaiting it.
    reader.stop();
  });
  return reader.readIncomingPayload().map(parseShareUri);
});
