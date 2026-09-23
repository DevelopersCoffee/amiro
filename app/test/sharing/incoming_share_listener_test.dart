import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/incoming_share_listener.dart';
import 'package:amiro_app/sharing/sharing_providers.dart';

// NFC receive is no longer wired into `IncomingShareListener` — round 3 of
// the final review removed the automatic, always-listening NFC read
// session (what was `incomingNfcShareProvider`) in favor of an explicit,
// on-demand single session started from `NfcReceiveScreen`. See that
// file and `IncomingShareListener`'s doc comment for why. This test file
// now only covers the deep-link path, which is unaffected.
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
}
