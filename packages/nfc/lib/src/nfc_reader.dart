import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

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
          final records = message?.records;
          final record = (records == null || records.isEmpty) ? null : records.first;
          if (record != null) {
            final text = decodeNdefTextPayload(record.payload);
            if (text != null) _controller.add(text);
          }
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

/// Decodes an NDEF well-known text record's payload to its text content.
///
/// Pure, hardware-independent logic pulled out of [ManagerNfcReader] as its
/// own top-level function so it can be unit-tested directly (see
/// `test/nfc_reader_test.dart`) without a real NFC session — the same
/// seam-and-fake approach used for `ThermionFilamentSurface` in
/// `avatar_renderer` (design spec §8).
///
/// NDEF well-known text records store a status byte + IANA language code
/// before the actual text — strip that prefix rather than assume offset 0,
/// since the language code length is encoded in the status byte's low bits
/// (typically 2 for "en", but not guaranteed). Returns `null` for an empty
/// payload or a language-code length that would overflow the payload.
String? decodeNdefTextPayload(Uint8List payload) {
  if (payload.isEmpty) return null;
  final statusByte = payload[0];
  final languageCodeLength = statusByte & 0x3F;
  final textStart = 1 + languageCodeLength;
  if (textStart > payload.length) return null;
  return String.fromCharCodes(payload.sublist(textStart));
}
