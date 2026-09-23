import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/incoming_share_listener.dart';
import 'package:amiro_app/sharing/sharing_providers.dart';

/// A fake [NfcReader] whose `readIncomingPayload()` stream is driven
/// directly by the test — stands in for real NFC hardware, which
/// `ManagerNfcReader` needs and can't be exercised in a widget test (see
/// `packages/nfc/lib/src/nfc_reader.dart`).
class _FakeNfcReader implements NfcReader {
  final _controller = StreamController<String>.broadcast();
  int stopCallCount = 0;

  void emit(String payload) => _controller.add(payload);

  @override
  Stream<String> readIncomingPayload() => _controller.stream;

  @override
  Future<void> stop() async => stopCallCount++;
}

void main() {
  testWidgets(
    'a valid deep link on incomingShareLinkProvider navigates to SharedProfileScreen',
    (tester) async {
      final linkController = StreamController<SharedProfile?>();
      addTearDown(linkController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingShareLinkProvider.overrideWith((ref) => linkController.stream),
            nfcReaderProvider.overrideWithValue(_FakeNfcReader()),
          ],
          child: MaterialApp(
            home: const IncomingShareListener(
              child: Scaffold(body: Text('home')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('Shared Amiro'), findsNothing);

      linkController.add(
        const SharedProfile(id: 'id-1', displayName: 'Ada', username: 'ada'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shared Amiro'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
    },
  );

  testWidgets(
    'a null (unparseable) deep link does not navigate',
    (tester) async {
      final linkController = StreamController<SharedProfile?>();
      addTearDown(linkController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingShareLinkProvider.overrideWith((ref) => linkController.stream),
            nfcReaderProvider.overrideWithValue(_FakeNfcReader()),
          ],
          child: MaterialApp(
            home: const IncomingShareListener(
              child: Scaffold(body: Text('home')),
            ),
          ),
        ),
      );
      await tester.pump();

      linkController.add(null);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('Shared Amiro'), findsNothing);
    },
  );

  testWidgets(
    'a valid NFC tag read navigates to SharedProfileScreen',
    (tester) async {
      final reader = _FakeNfcReader();
      final linkController = StreamController<SharedProfile?>();
      addTearDown(linkController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingShareLinkProvider.overrideWith((ref) => linkController.stream),
            nfcReaderProvider.overrideWithValue(reader),
          ],
          child: MaterialApp(
            home: const IncomingShareListener(
              child: Scaffold(body: Text('home')),
            ),
          ),
        ),
      );
      await tester.pump();

      final uri = buildShareUri(
        Identity(id: 'id-1', displayName: 'Ada', username: 'ada'),
      );
      reader.emit(uri);
      await tester.pumpAndSettle();

      expect(find.text('Shared Amiro'), findsOneWidget);
    },
  );

  testWidgets(
    'a tag read that does not decode to a valid share link does not navigate',
    (tester) async {
      final reader = _FakeNfcReader();
      final linkController = StreamController<SharedProfile?>();
      addTearDown(linkController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingShareLinkProvider.overrideWith((ref) => linkController.stream),
            nfcReaderProvider.overrideWithValue(reader),
          ],
          child: MaterialApp(
            home: const IncomingShareListener(
              child: Scaffold(body: Text('home')),
            ),
          ),
        ),
      );
      await tester.pump();

      reader.emit('not a share link');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('Shared Amiro'), findsNothing);
    },
  );
}
