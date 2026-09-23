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
///
/// NFC receive is on-demand only (see `NfcReceiveScreen`) — this provider
/// is read once when the user explicitly taps "Receive via NFC", not
/// watched anywhere at app root. Two earlier rounds tried auto-starting a
/// read session at app launch (via what was `incomingNfcShareProvider`,
/// listened to by `IncomingShareListener`), gated behind a
/// `nfcEmulatingProvider` coordination flag to avoid contending with this
/// device's own HCE emulation. That approach only ever covered Android
/// (the only platform that can emulate) and still left iOS popping the
/// system NFC scan sheet at every launch with no way to restart it once
/// that first session ended. Making receive an explicit, user-triggered,
/// single-session action removes the automatic-start problem entirely on
/// both platforms, so both that provider and the flag were removed.
final nfcReaderProvider = Provider<NfcReader>((ref) {
  throw UnimplementedError('nfcReaderProvider must be overridden');
});
