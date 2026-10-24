import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import 'profile_cloud.dart';

/// Overridden in `main.dart` with the Supabase-backed cloud. Tests keep
/// the no-network default.
final profileCloudProvider = Provider<ProfileCloud>((ref) {
  return const NoopProfileCloud();
});

/// Overridden in `main.dart` with a real [IsarIdentityRepository] once
/// Isar is opened; overridden in tests with an in-memory fake.
final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  throw UnimplementedError('identityRepositoryProvider must be overridden');
});

class CurrentIdentityNotifier extends AsyncNotifier<Identity?> {
  @override
  Future<Identity?> build() {
    return ref.read(identityRepositoryProvider).getCurrent();
  }

  Future<void> save(Identity identity) async {
    final repo = ref.read(identityRepositoryProvider);
    await repo.save(identity);
    state = AsyncData(identity);
    // build() captures the row when it starts. If that future resolves
    // after this write, Riverpod would put the stale null back. Re-read
    // once that queued completion has run.
    await Future<void>.value();
    final latest = await repo.getCurrent();
    if (latest != null) {
      state = AsyncData(latest);
    }
  }
}

final currentIdentityProvider =
    AsyncNotifierProvider<CurrentIdentityNotifier, Identity?>(
      CurrentIdentityNotifier.new,
    );
