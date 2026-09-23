import 'package:identity_core/identity_core.dart';

class InMemoryIdentityRepository implements IdentityRepository {
  Identity? stored;

  InMemoryIdentityRepository([this.stored]);

  @override
  Future<Identity?> getCurrent() async => stored;

  @override
  Future<void> save(Identity identity) async => stored = identity;

  @override
  Future<void> clear() async => stored = null;
}
