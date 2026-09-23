import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/sharing/share_screen.dart';
import 'package:amiro_app/sharing/sharing_providers.dart' show nfcEmulatorProvider;

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? stored;
  _InMemoryIdentityRepository(this.stored);

  @override
  Future<Identity?> getCurrent() async => stored;
  @override
  Future<void> save(Identity identity) async => stored = identity;
  @override
  Future<void> clear() async => stored = null;
}

Widget _screen(NfcEmulator emulator, Identity identity) {
  return ProviderScope(
    overrides: [
      identityRepositoryProvider.overrideWithValue(_InMemoryIdentityRepository(identity)),
      nfcEmulatorProvider.overrideWithValue(emulator),
    ],
    child: const MaterialApp(home: ShareScreen()),
  );
}

void main() {
  testWidgets('shows a QR code for the current identity', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(NoopNfcEmulator(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shareQrCode')), findsOneWidget);
  });

  testWidgets('shows NFC section when the emulator can emulate', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(_FakeCanEmulate(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfcShareSection')), findsOneWidget);
  });

  testWidgets('hides NFC section when the emulator cannot emulate', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(NoopNfcEmulator(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfcShareSection')), findsNothing);
  });
}

class _FakeCanEmulate implements NfcEmulator {
  @override
  bool get canEmulate => true;
  @override
  Future<void> writeIdentityPayload(String uri) async {}
  @override
  Future<void> stopEmulating() async {}
}
