import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amiro_qr/amiro_qr.dart';
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

  @override
  void dispose() {
    // Stop emulating when the screen goes away so a stale identity doesn't
    // keep being broadcast after the user navigates elsewhere. Best-effort —
    // nothing awaits it since dispose() can't be async.
    if (_emulating) {
      ref.read(nfcEmulatorProvider).stopEmulating();
      // Let `incomingNfcShareProvider` resume reading now that this
      // screen (and its emulation) is gone.
      ref.read(nfcEmulatingProvider.notifier).state = false;
    }
    super.dispose();
  }

  Future<void> _toggleNfcEmulate(String shareUri) async {
    final emulator = ref.read(nfcEmulatorProvider);
    // `_emulating` must only flip once the platform call actually
    // succeeds — otherwise a thrown PlatformException leaves the UI
    // toggled to a state the native side never reached (e.g. showing
    // "Stop NFC sharing" when the HCE service was never started).
    try {
      if (_emulating) {
        await emulator.stopEmulating();
      } else {
        await emulator.writeIdentityPayload(shareUri);
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
    ref.read(nfcEmulatingProvider.notifier).state = nowEmulating;
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
