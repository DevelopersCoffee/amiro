import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sharing/sharing.dart';

import 'shared_profile_screen.dart';
import 'sharing_providers.dart';

/// Wraps [child] and watches for an incoming share arriving via either
/// receive path this app supports — an `amiro://` deep link
/// ([incomingShareLinkProvider]) or an NFC tag read
/// ([incomingNfcShareProvider]) — pushing [SharedProfileScreen] as soon as
/// either stream produces a successfully-parsed [SharedProfile].
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

    ref.listen<AsyncValue<SharedProfile?>>(incomingNfcShareProvider, (
      previous,
      next,
    ) {
      final profile = next.valueOrNull;
      if (profile != null) _showProfile(context, profile);
    });

    return child;
  }
}
