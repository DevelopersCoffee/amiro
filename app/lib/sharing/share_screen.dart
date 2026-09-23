import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amiro_qr/amiro_qr.dart';
import 'package:nfc/nfc.dart';
import 'package:sharing/sharing.dart';

import '../identity/identity_providers.dart';
import 'qr_scan_screen.dart';
import 'sharing_providers.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _emulating = false;

  // Captured once here, not re-read in `dispose()`. flutter_riverpod 2.6.1
  // throws `StateError: Cannot use "ref" after the widget was disposed`
  // if `ref.read`/`ref.watch` is called from inside `dispose()` — by the
  // time `dispose()` runs the widget is already unmounted. Because that
  // throw happened *before* any of the cleanup below it executed, the
  // previous implementation's `dispose()` silently did nothing at all:
  // switching tabs (or otherwise navigating away) while "Start NFC
  // sharing" was active left the phone still physically emulating the NFC
  // tag indefinitely, and the round-2 coordination flag stuck at `true`.
  // These two fields are the standard Riverpod fix for "I need to act on a
  // provider-derived object when this widget is disposed": grab the object
  // once while `ref` is still valid, store it directly, and have
  // `dispose()` call methods on it without touching `ref` at all.
  late final NfcEmulator _emulator;
  late final StateController<bool> _nfcEmulating;

  @override
  void initState() {
    super.initState();
    _emulator = ref.read(nfcEmulatorProvider);
    _nfcEmulating = ref.read(nfcEmulatingProvider.notifier);
  }

  @override
  void dispose() {
    // Stop emulating when the screen goes away so a stale identity doesn't
    // keep being broadcast after the user navigates elsewhere. Best-effort
    // and fire-and-forget: `stopEmulating()` is async, `dispose()` can't
    // be, and there's no user-facing surface left to report a failure to,
    // so any error is swallowed rather than becoming an unhandled future
    // exception.
    if (_emulating) {
      unawaited(_emulator.stopEmulating().catchError((_) {}));
      // Let `incomingNfcShareProvider` resume reading now that this
      // screen (and its emulation) is gone. `_nfcEmulating` is the
      // `StateController` captured in `initState`, not `ref` — see the
      // field doc above for why that distinction is what makes this line
      // safe to run from inside `dispose()`.
      _nfcEmulating.state = false;
    }
    super.dispose();
  }

  Future<void> _toggleNfcEmulate(String shareUri) async {
    // `_emulating` must only flip once the platform call actually
    // succeeds — otherwise a thrown PlatformException leaves the UI
    // toggled to a state the native side never reached (e.g. showing
    // "Stop NFC sharing" when the HCE service was never started).
    try {
      if (_emulating) {
        await _emulator.stopEmulating();
      } else {
        await _emulator.writeIdentityPayload(shareUri);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC sharing failed: $error')),
      );
      return;
    }
    if (!mounted) return;
    // Flip `nfcEmulatingProvider` in lockstep with `_emulating` so
    // `incomingNfcShareProvider` pauses reading for exactly as long as
    // this device is actively emulating a tag to send — the two would
    // otherwise contend for the same NFC radio mode (see that provider's
    // doc comment in `sharing_providers.dart`).
    final nowEmulating = !_emulating;
    _nfcEmulating.state = nowEmulating;
    setState(() => _emulating = nowEmulating);
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    final emulator = ref.watch(nfcEmulatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share'),
        actions: [
          IconButton(
            key: const Key('openScannerButton'),
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            ),
          ),
        ],
      ),
      body: identityAsync.when(
        data: (identity) {
          if (identity == null) {
            return const Center(child: Text('Create your identity first'));
          }
          final shareUri = buildShareUri(identity);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                key: const Key('shareQrCode'),
                child: buildQrWidget(shareUri),
              ),
              if (emulator.canEmulate) ...[
                const SizedBox(height: 32),
                Column(
                  key: const Key('nfcShareSection'),
                  children: [
                    const Text('Or tap another phone to share'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _toggleNfcEmulate(shareUri),
                      child: Text(_emulating ? 'Stop NFC sharing' : 'Start NFC sharing'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
