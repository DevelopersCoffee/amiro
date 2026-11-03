import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/identity/profile_cloud.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';

class _TransientClaimCloud implements ProfileCloud {
  @override
  bool get supportsRestore => true;

  @override
  Future<String?> recoveryCode() async => null;

  @override
  Future<bool> push(Identity identity) async => false;

  @override
  Future<Identity?> pull() async => null;

  @override
  Future<Identity?> claim(String code) async {
    throw SessionRefreshFailure(503);
  }

  @override
  Future<RevokeBackupResult> revokeBackup({String? identityId}) async {
    return const RevokeBackupResult.ok();
  }
}

void main() {
  testWidgets('Y9: transient claim failure shows a connection message', (
    tester,
  ) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(
            CloudBackupPreferences.inMemory(),
          ),
          profileCloudProvider.overrideWithValue(_TransientClaimCloud()),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('restoreCodeField')));

    await tester.ensureVisible(find.byKey(const Key('restoreCodeField')));
    await tester.enterText(
      find.byKey(const Key('restoreCodeField')),
      '1234567890123456',
    );
    await tester.tap(find.byKey(const Key('restoreCodeButton')));
    await pumpShort(tester, frames: 8);

    expect(
      find.textContaining('Could not reach the backup service'),
      findsOneWidget,
    );
    expect(find.text('That code did not match an Amiro'), findsNothing);
  });
}
