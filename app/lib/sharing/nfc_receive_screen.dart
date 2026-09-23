import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nfc/nfc.dart';
import 'package:sharing/sharing.dart';

import 'shared_profile_screen.dart';
import 'sharing_providers.dart';

/// Pushed when the user taps "Receive via NFC" on [ShareScreen]. Starts a
/// single, explicit, bounded NFC read session and navigates to
/// [SharedProfileScreen] on a successful parse — mirroring how
/// `QrScanScreen` pushes the same screen for the QR path.
///
/// NFC receive is deliberately on-demand rather than automatic. Two prior
/// fix rounds tried to make [nfcReaderProvider]'s reader listen
/// automatically at app root (in `IncomingShareListener`), gated behind a
/// flag tracking whether this device was itself emulating a tag to send.
/// That only ever covered Android (the only platform that can emulate) and
/// still left iOS auto-popping the system "Ready to Scan" sheet at every
/// app launch, with no way to restart a session once the first one ended.
/// Making the user explicitly start each read removes both problems: there
/// is no automatic start on either platform, so nothing to contend with
/// this device's own emulation and nothing to auto-pop on launch. This
/// screen's session is bounded to its own lifetime — it starts reading in
/// `initState` and always stops in `dispose`, whether that's from a
/// successful read, a Cancel tap, or a read error.
class NfcReceiveScreen extends ConsumerStatefulWidget {
  const NfcReceiveScreen({super.key});

  @override
  ConsumerState<NfcReceiveScreen> createState() => _NfcReceiveScreenState();
}

class _NfcReceiveScreenState extends ConsumerState<NfcReceiveScreen> {
  // Captured once here, not re-read in `dispose()` — `dispose()` can't
  // touch `ref` (flutter_riverpod throws `StateError` if it does, since
  // the widget's already been torn down by the time `dispose()` runs).
  // This is the same fix applied to `ShareScreen`'s `dispose()`, which is
  // what round 3 of this review exists to fix: a `ref.read()` inside
  // `dispose()` there was silently swallowing all cleanup because the
  // thrown `StateError` meant nothing after it ever ran.
  late final NfcReader _reader;
  StreamSubscription<String>? _subscription;
  bool _handled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reader = ref.read(nfcReaderProvider);
    _subscription = _reader.readIncomingPayload().listen(
      _onPayload,
      onError: (Object error, StackTrace stack) {
        if (!mounted) return;
        setState(() => _error = 'NFC read failed: $error');
      },
    );
  }

  void _onPayload(String payload) {
    if (_handled) return;
    final profile = parseShareUri(payload);
    if (profile == null) return;

    _handled = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SharedProfileScreen(profile: profile)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // Best-effort, fire-and-forget — same reasoning as `ShareScreen`'s
    // dispose fix: `stop()` is async and `dispose()` can't be, and by the
    // time this runs there's no user-facing surface left to report an
    // error to, so it's swallowed rather than left as an unhandled future
    // exception.
    unawaited(_reader.stop().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive via NFC')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nfc, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Hold your phone near the other device',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('cancelNfcReceiveButton'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
