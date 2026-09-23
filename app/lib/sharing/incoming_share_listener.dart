import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sharing/sharing.dart';

import 'shared_profile_screen.dart';
import 'sharing_providers.dart';

/// Wraps [child] and watches for an incoming share arriving via an
/// `amiro://` deep link ([incomingShareLinkProvider]), pushing
/// [SharedProfileScreen] as soon as the stream produces a
/// successfully-parsed [SharedProfile].
///
/// NFC receive is deliberately *not* wired in here — see
/// `NfcReceiveScreen` and `sharing_providers.dart`'s `nfcReaderProvider`
/// doc comment for why an automatically-started, always-listening NFC
/// read session (this file's previous behavior, via what was
/// `incomingNfcShareProvider`) caused two rounds of unfixable lifecycle
/// bugs and was replaced with an explicit, on-demand, single-session flow
/// instead. Deep links don't have that problem — they don't contend for
/// exclusive hardware the way NFC reader mode does — so that half of this
/// listener is untouched.
///
/// Lives inside `MaterialApp.home` (see `app.dart`), not in
/// `MaterialApp.builder` — a `builder` context sits *above* the app's
/// `Navigator`, so `Navigator.of(context)` there would find nothing to
/// push onto. Placing this widget under `home` instead means its
/// `context` is already inside the Navigator, the same way
/// `QrScanScreen` pushes `SharedProfileScreen` for the QR path.
class IncomingShareListener extends ConsumerWidget {
  final Widget child;

  const IncomingShareListener({super.key, required this.child});

  void _showProfile(BuildContext context, SharedProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SharedProfileScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<SharedProfile?>>(incomingShareLinkProvider, (
      previous,
      next,
    ) {
      final profile = next.valueOrNull;
      if (profile != null) _showProfile(context, profile);
    });

    return child;
  }
}
