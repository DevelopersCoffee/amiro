import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

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
    await ref.read(identityRepositoryProvider).save(identity);
    state = AsyncData(identity);
  }
}

final currentIdentityProvider =
    AsyncNotifierProvider<CurrentIdentityNotifier, Identity?>(CurrentIdentityNotifier.new);
