import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:sharing/sharing.dart';

/// Listens for an incoming NDEF tag read (either a physical tag or an
/// Android device emulating one via HCE) and emits its text payload.
/// Not directly unit-testable — needs real NFC hardware. See the device
/// spike note in the design spec §8.
abstract class NfcReader {
  Stream<String> readIncomingPayload();
  Future<void> stop();
}

class ManagerNfcReader implements NfcReader {
  final _controller = StreamController<String>.broadcast();
  bool _sessionActive = false;

  @override
  Stream<String> readIncomingPayload() {
    if (!_sessionActive) {
      _sessionActive = true;
      // `readIncomingPayload()` is synchronous (the `NfcReader` interface
      // returns a `Stream`, not a `Future`), but starting a session is
      // async — checking availability, then awaiting `startSession` — so
      // that work happens fire-and-forget here. It's still fully awaited
      // *inside* `_startSession`, so a rejected `startSession` (no NFC
      // hardware, permission denied, etc.) can't become an unhandled
      // async error, and `_sessionActive` gets reset on failure so a
      // later call can retry.
      unawaited(_startSession());
    }
    return _controller.stream;
  }

  Future<void> _startSession() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (availability != NfcAvailability.enabled) {
        // No NFC hardware, or NFC is present but turned off — nothing to
        // start. Reset so a later call (e.g. after the user enables NFC
        // in system settings) can try again.
        _sessionActive = false;
        return;
      }
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          // nfc_manager 4.x has no cross-platform `Ndef` class — each
          // platform exposes its own (`NdefAndroid`/`NdefIos`), both with
          // the same `cachedNdefMessage`/`records` shape, so try both.
          final message =
              NdefAndroid.from(tag)?.cachedNdefMessage ??
              NdefIos.from(tag)?.cachedNdefMessage;
          if (message == null) return;
          // Every record is considered (an Android Application Record may
          // come first) and text is decoded strictly by the sharing
          // package's NDEF adapter, so both the encounter link and a legacy
          // share link reach the caller as text.
          final text = amiroLinkTextFromNdef([
            for (final record in message.records)
              NdefRecordData(
                tnf: record.typeNameFormat.index, // enum order == NDEF TNF codes
                type: record.type,
                payload: record.payload,
              ),
          ]);
          if (text != null) _controller.add(text);
        },
        // iOS's `NFCTagReaderSession` invalidates itself automatically —
        // after a successful read (`invalidateAfterFirstReadIos` defaults
        // to true), on a timeout, or when the user dismisses the system
        // "Ready to Scan" sheet — and `nfc_manager` surfaces that only
        // through this callback, not through the `startSession` future
        // (which completes once the session *starts*, not when it ends).
        // Without resetting `_sessionActive` here, a finished iOS session
        // could never be restarted by a later `readIncomingPayload()`
        // call. Android's reader mode has no equivalent auto-invalidation
        // (it runs until `stop()` calls `stopSession()`), so this
        // callback simply never fires there — resetting the flag here is
        // harmless on that platform.
        onSessionErrorIos: (_) {
          _sessionActive = false;
        },
      );
    } catch (_) {
      // `startSession` itself rejected (e.g. a platform exception because
      // there's no NFC hardware at all) — reset so a later call can retry
      // rather than being permanently stuck with `_sessionActive == true`
      // and no session actually running.
      _sessionActive = false;
    }
  }

  @override
  Future<void> stop() async {
    if (_sessionActive) {
      _sessionActive = false;
      await NfcManager.instance.stopSession();
    }
  }
}
