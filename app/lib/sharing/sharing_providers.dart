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
