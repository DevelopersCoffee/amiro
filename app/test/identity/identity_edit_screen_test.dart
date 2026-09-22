import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? _stored;

  @override
  Future<Identity?> getCurrent() async => _stored;

  @override
  Future<void> save(Identity identity) async => _stored = identity;

  @override
  Future<void> clear() async => _stored = null;
}

void main() {
  testWidgets('entering a display name and saving persists it', (tester) async {
    final repo = _InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    final saved = await repo.getCurrent();
    expect(saved!.displayName, 'Uday');
    expect(saved.username, 'uday');
  });

  testWidgets('toggling a field private excludes it from publicFields', (tester) async {
    final repo = _InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.enterText(find.byKey(const Key('emailField')), 'coffee.devloper@gmail.com');
    // Default is private; explicitly flip to public then back to private
    // to exercise the toggle path deterministically.
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    final saved = await repo.getCurrent();
    expect(saved!.publicFields().containsKey('email'), isFalse);
  });
}
