import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/nfc_receive_screen.dart';
import 'package:amiro_app/sharing/sharing_providers.dart';

/// A fake [NfcReader] whose `readIncomingPayload()` stream is driven
/// directly by the test — stands in for real NFC hardware, which
/// `ManagerNfcReader` needs and can't be exercised in a widget test (see
/// `packages/nfc/lib/src/nfc_reader.dart`). Same pattern used elsewhere in
/// this test suite for the same reason.
class _FakeNfcReader implements NfcReader {
  final _controller = StreamController<String>.broadcast();
  int stopCallCount = 0;

  void emit(String payload) => _controller.add(payload);
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<String> readIncomingPayload() => _controller.stream;

  @override
  Future<void> stop() async => stopCallCount++;
}

Widget _screen(NfcReader reader) {
  return ProviderScope(
    overrides: [nfcReaderProvider.overrideWithValue(reader)],
    child: const MaterialApp(home: NfcReceiveScreen()),
  );
}

void main() {
  testWidgets(
    'a valid NFC tag read navigates to SharedProfileScreen and stops the reader',
    (tester) async {
      final reader = _FakeNfcReader();
      await tester.pumpWidget(_screen(reader));
      await tester.pump();

      final uri = buildShareUri(
        Identity(id: 'id-1', displayName: 'Ada', username: 'ada'),
      );
      reader.emit(uri);
      await tester.pumpAndSettle();

      expect(find.text('Shared Amiro'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(reader.stopCallCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a tag read that does not decode to a valid share link does not navigate',
    (tester) async {
      final reader = _FakeNfcReader();
      await tester.pumpWidget(_screen(reader));
      await tester.pump();

      reader.emit('not a share link');
      await tester.pumpAndSettle();

      expect(find.text('Receive via NFC'), findsOneWidget);
      expect(find.text('Shared Amiro'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a read error shows a message instead of crashing',
    (tester) async {
      final reader = _FakeNfcReader();
      await tester.pumpWidget(_screen(reader));
      await tester.pump();

      reader.emitError(Exception('no NFC hardware'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('NFC read failed'), findsOneWidget);
    },
  );

  testWidgets(
    'the cancel button pops the screen and stops the reader session, '
    'without throwing',
    (tester) async {
      // Exercises the same dispose()-touching-ref hazard as
      // ShareScreen's fix: `_reader` is captured once in initState and
      // used directly in dispose(), never re-read from `ref` there.
      final reader = _FakeNfcReader();
      await tester.pumpWidget(_screen(reader));
      await tester.pump();

      expect(reader.stopCallCount, 0);

      await tester.tap(find.byKey(const Key('cancelNfcReceiveButton')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reader.stopCallCount, 1);
    },
  );
}
