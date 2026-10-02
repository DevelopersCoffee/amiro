import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';

void main() {
  testWidgets('entering a display name and saving persists it', (tester) async {
    useTallTestViewport(tester);
    final repo = InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.ensureVisible(find.byKey(const Key('saveButton')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump();

    final saved = await repo.getCurrent();
    expect(saved!.displayName, 'Uday');
    expect(saved.username, 'uday');
    expect(saved.avatarGender, 'male');
  });

  testWidgets('selecting female persists avatarGender', (tester) async {
    useTallTestViewport(tester);
    final repo = InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('displayNameField')), 'Alex');
    await tester.enterText(find.byKey(const Key('usernameField')), 'alex');
    await tester.ensureVisible(find.byKey(const Key('saveButton')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump();

    expect((await repo.getCurrent())!.avatarGender, 'female');
  });

  testWidgets('toggling a field private excludes it from publicFields', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final repo = InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'coffee.devloper@gmail.com',
    );
    await tester.ensureVisible(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.pump();
    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isTrue,
      reason: 'first tap should flip the email toggle from private to public',
    );
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.ensureVisible(find.byKey(const Key('saveButton')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump();

    final saved = await repo.getCurrent();
    expect(saved!.publicFields().containsKey('email'), isFalse);
  });

  testWidgets('groups fields under Profile and Contact section labels', (
    tester,
  ) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(),
          ),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('AVATAR'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('CONTACT'), findsOneWidget);
    final profileY = tester.getTopLeft(find.text('PROFILE')).dy;
    final contactY = tester.getTopLeft(find.text('CONTACT')).dy;
    final nameY = tester
        .getTopLeft(find.byKey(const Key('displayNameField')))
        .dy;
    await tester.ensureVisible(find.byKey(const Key('emailField')));
    final emailY = tester.getTopLeft(find.byKey(const Key('emailField'))).dy;
    expect(profileY, lessThan(nameY));
    expect(nameY, lessThan(contactY));
    expect(contactY, lessThan(emailY));
  });

  testWidgets(
    'existing field and toggle behaviour is unaffected by the new grouping',
    (tester) async {
      useTallTestViewport(tester);
      final repo = InMemoryIdentityRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [identityRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: IdentityEditScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('bioField')), 'Engineer');
      await tester.ensureVisible(find.byKey(const Key('saveButton')));
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pump();

      expect((await repo.getCurrent())!.bio, 'Engineer');
    },
  );
}
