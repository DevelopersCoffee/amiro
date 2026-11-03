import 'package:amiro_app/launch/startup_cloud_restore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

void main() {
  test('N10: pull failure does not throw and does not save', () async {
    var saved = false;
    final ok = await tryRestoreIdentityFromCloud(
      getCurrent: () async => null,
      isBackupEnabled: () async => true,
      pull: () async => throw StateError('keystore or network failure'),
      save: (_) async => saved = true,
    );
    expect(ok, isFalse);
    expect(saved, isFalse);
  });

  test('skips pull when backup is off', () async {
    var pullCalls = 0;
    await tryRestoreIdentityFromCloud(
      getCurrent: () async => null,
      isBackupEnabled: () async => false,
      pull: () async {
        pullCalls += 1;
        return null;
      },
      save: (_) async {},
    );
    expect(pullCalls, 0);
  });

  test('skips pull when identity already exists', () async {
    var pullCalls = 0;
    const identity = Identity(id: '1', displayName: 'A', username: 'a');
    await tryRestoreIdentityFromCloud(
      getCurrent: () async => identity,
      isBackupEnabled: () async => true,
      pull: () async {
        pullCalls += 1;
        return null;
      },
      save: (_) async {},
    );
    expect(pullCalls, 0);
  });

  test('saves when pull returns an identity', () async {
    Identity? savedIdentity;
    const restored = Identity(id: '2', displayName: 'B', username: 'b');
    final ok = await tryRestoreIdentityFromCloud(
      getCurrent: () async => null,
      isBackupEnabled: () async => true,
      pull: () async => restored,
      save: (identity) async => savedIdentity = identity,
    );
    expect(ok, isTrue);
    expect(savedIdentity, restored);
  });
}
