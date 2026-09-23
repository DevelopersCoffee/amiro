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

  testWidgets(
    'stops emulating when the screen is disposed mid-emulation, without '
    'throwing',
    (tester) async {
      // Regression test for the round-3 review finding: `dispose()` used
      // to call `ref.read(...)` to reach the emulator and reset the
      // coordination flag. In flutter_riverpod 2.6.1 that throws
      // `StateError` (ref can't be touched after the widget is disposed),
      // which meant NONE of dispose()'s cleanup ever ran — `stopEmulating`
      // was silently never called and the phone kept physically emulating
      // the NFC tag after the user navigated away. The two previous fix
      // rounds' tests only exercised the provider/flag logic in isolation
      // and never drove the real widget disposal path, which is why this
      // survived both of them — this test mounts the real `ShareScreen`,
      // starts real emulation through its own button, and then disposes it
      // exactly the way `app.dart`'s `_RootTabs` does when switching tabs
      // (`screens[_index]` unmounts the off-screen tab): by replacing the
      // widget tree, not by calling internal methods directly.
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      final emulator = _FakeCanEmulate();

      await tester.pumpWidget(_screen(emulator, identity));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start NFC sharing'));
      await tester.pumpAndSettle();

      expect(find.text('Stop NFC sharing'), findsOneWidget);
      expect(emulator.stopCallCount, 0);

      // Dispose ShareScreen by swapping in a different widget tree — this
      // is what actually tears the widget down and calls its dispose(),
      // unlike testing the provider/notifier logic on its own.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // With the bug present, disposal throws `StateError` inside
      // dispose(), which flutter_test surfaces via takeException() — and
      // stopCallCount stays 0 because the throw happens before
      // stopEmulating() is ever reached.
      expect(tester.takeException(), isNull);
      expect(emulator.stopCallCount, 1);
    },
  );

  testWidgets(
    'disables the receive-via-NFC button while emulating',
    (tester) async {
      // Receive is on-demand and user-triggered now, so there's no shared
      // provider coordinating it with send-side emulation the way the
      // removed `nfcEmulatingProvider` did. Starting a read while this
      // device is itself emulating a tag to send would still fight it for
      // the NFC radio on Android, so this is guarded locally instead.
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      await tester.pumpWidget(_screen(_FakeCanEmulate(), identity));
      await tester.pumpAndSettle();

      IconButton receiveButton() => tester.widget<IconButton>(
        find.byKey(const Key('receiveNfcButton')),
      );

      expect(receiveButton().onPressed, isNotNull);

      await tester.tap(find.text('Start NFC sharing'));
      await tester.pumpAndSettle();

      expect(receiveButton().onPressed, isNull);
    },
  );
}

class _FakeCanEmulate implements NfcEmulator {
  int stopCallCount = 0;

  @override
  bool get canEmulate => true;
  @override
  Future<void> writeIdentityPayload(String uri) async {}
  @override
  Future<void> stopEmulating() async {
    stopCallCount++;
  }
}
