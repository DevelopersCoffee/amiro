import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sharing/sharing.dart';

import 'package:amiro_app/discovery/encounter_screen.dart';
import 'package:amiro_app/sharing/incoming_share_listener.dart';
import 'package:amiro_app/sharing/scan_result.dart';
import 'package:amiro_app/sharing/sharing_providers.dart';

import '../discovery/support.dart';

// NFC receive is no longer wired into `IncomingShareListener` — round 3 of
// the final review removed the automatic, always-listening NFC read
// session (what was `incomingNfcShareProvider`) in favor of an explicit,
// on-demand single session started from `NfcReceiveScreen`. See that
// file and `IncomingShareListener`'s doc comment for why. This test file
// now only covers the deep-link path, which is unaffected.
void main() {
  Future<StreamController<ScanResult>> pump(WidgetTester tester) async {
    final linkController = StreamController<ScanResult>();
    addTearDown(linkController.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...TestApp().overrides,
          incomingShareLinkProvider.overrideWith(
            (ref) => linkController.stream,
          ),
        ],
        child: const MaterialApp(
          home: IncomingShareListener(child: Scaffold(body: Text('home'))),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
    return linkController;
  }

  testWidgets('a legacy share deep link navigates to SharedProfileScreen', (
    tester,
  ) async {
    final links = await pump(tester);

    links.add(
      const LegacyProfileLink(
        SharedProfile(id: 'id-1', displayName: 'Ada', username: 'ada'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared Amiro'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('an encounter deep link navigates to the encounter screen', (
    tester,
  ) async {
    final links = await pump(tester);

    links.add(EncounterLink(encounterFor()));
    await tester.pumpAndSettle();

    expect(find.byType(EncounterScreen), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('an invalid or foreign deep link does not navigate', (
    tester,
  ) async {
    final links = await pump(tester);

    links.add(const NotAmiroLink());
    links.add(
      const InvalidAmiroLink(
        SharingPayloadException(PayloadErrorKind.malformed, 'bad'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(EncounterScreen), findsNothing);
    expect(find.text('Shared Amiro'), findsNothing);
  });
}
