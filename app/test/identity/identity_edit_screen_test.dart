import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import 'in_memory_identity_repository.dart';

void main() {
  testWidgets('entering a display name and saving persists it', (tester) async {
    final repo = InMemoryIdentityRepository();

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
    final repo = InMemoryIdentityRepository();

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
    await tester.pump();
    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isTrue,
      reason: 'first tap should flip the email toggle from private to public',
    );
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    final saved = await repo.getCurrent();
    expect(saved!.publicFields().containsKey('email'), isFalse);
  });
}
