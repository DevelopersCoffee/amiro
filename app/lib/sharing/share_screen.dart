import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nfc/nfc.dart';

import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
import '../identity/identity_providers.dart';
import '../store/store_providers.dart';
import 'identity_card.dart';
import 'nfc_receive_screen.dart';
import 'own_encounter.dart';
import 'qr_scan_screen.dart';
import 'sharing_providers.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _emulating = false;

  // Captured once here, not re-read in `dispose()` — see the previous
  // commit's fix for why touching `ref` inside `dispose()` is unsafe in
  // flutter_riverpod 2.6.1.
  late final NfcEmulator _emulator;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _emulator = ref.read(nfcEmulatorProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    // The card needs the user's avatar loaded (same as the Avatar and Store
    // tabs); rebuild once it is so the card can replace the spinner.
    ensureAvatarLoaded(ref).then((_) {
      if (mounted) setState(() {});
    });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('NFC sharing failed: $error')));
      return;
    }
    if (!mounted) return;
    setState(() => _emulating = !_emulating);
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    final emulator = ref.watch(nfcEmulatorProvider);
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const <String>{};
    final renderer = ref.watch(avatarRendererProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share'),
        actions: [
          IconButton(
            key: const Key('receiveNfcButton'),
            icon: const Icon(Icons.nfc),
            tooltip: _emulating
                ? 'Stop NFC sharing to receive'
                : 'Receive via NFC',
            // Disabled while this device is emulating its own tag to
            // send — starting a read session at the same time would fight
            // that emulation for the NFC radio (see `NfcReceiveScreen`'s
            // doc comment). Receive is only ever user-triggered now (not
            // auto-started anywhere), so this local flag is enough to
            // guard it — no shared cross-provider coordination state is
            // needed the way the removed `nfcEmulatingProvider` was.
            onPressed: _emulating
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NfcReceiveScreen()),
                  ),
          ),
          IconButton(
            key: const Key('openScannerButton'),
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QrScanScreen())),
          ),
        ],
      ),
      body: identityAsync.when(
        data: (identity) {
          if (identity == null) {
            return const Center(child: Text('Create your identity first'));
          }
          final payload = buildOwnEncounterPayload(
            identity: identity,
            definition: renderer.current,
            purchasedIds: owned,
          );
          if (payload == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // One link feeds both the QR code and the NFC tag.
          final shareUri = buildOwnEncounterUri(
            identity: identity,
            definition: renderer.current,
            purchasedIds: owned,
          );

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              IdentityCard(
                payload: payload,
                avatar: renderer.buildView(),
                qrData: shareUri,
              ),
              if (emulator.canEmulate) ...[
                const SizedBox(height: 32),
                Column(
                  key: const Key('nfcShareSection'),
                  children: [
                    const Text('Or tap another phone to share'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: shareUri == null
                          ? null
                          : () => _toggleNfcEmulate(shareUri),
                      child: Text(
                        _emulating ? 'Stop NFC sharing' : 'Start NFC sharing',
                      ),
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
