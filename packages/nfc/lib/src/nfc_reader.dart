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
      NfcManager.instance.startSession(
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
            final text = _decodeTextRecord(record.payload);
            if (text != null) _controller.add(text);
          }
        },
      );
    }
    return _controller.stream;
  }

  @override
  Future<void> stop() async {
    if (_sessionActive) {
      _sessionActive = false;
      await NfcManager.instance.stopSession();
    }
  }

  String? _decodeTextRecord(Uint8List payload) {
    // NDEF well-known text records store a status byte + IANA language
    // code before the actual text — strip that prefix rather than assume
    // offset 0, since the language code length is encoded in the status
    // byte's low bits (typically 2 for "en", but not guaranteed).
    if (payload.isEmpty) return null;
    final statusByte = payload[0];
    final languageCodeLength = statusByte & 0x3F;
    final textStart = 1 + languageCodeLength;
    if (textStart > payload.length) return null;
    return String.fromCharCodes(payload.sublist(textStart));
  }
}
