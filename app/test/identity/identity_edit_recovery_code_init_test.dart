import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/identity/profile_cloud.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';
import 'recording_profile_cloud.dart';

/// N8: [IdentityEditScreen] must tolerate [ProfileCloud.recoveryCode] failures.
class _ThrowingRecoveryCloud extends RecordingProfileCloud {
  @override
  Future<String?> recoveryCode() async {
    throw StateError('recovery code read failed');
  }
}

void main() {
  testWidgets('N8: recoveryCode failure does not break the identity screen', (
    tester,
  ) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(),
          ),
          profileCloudProvider.overrideWithValue(_ThrowingRecoveryCloud()),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpShort(tester, frames: 12);

    expect(find.text('Your Amiro'), findsOneWidget);
    expect(find.byKey(const Key('displayNameField')), findsOneWidget);
  });
}
