import 'package:discovery/discovery.dart';
import 'package:test/test.dart';

import 'discovery_repository_contract.dart';

void main() {
  group('InMemoryDiscoveryRepository', () {
    discoveryRepositoryContract(() async => InMemoryDiscoveryRepository());
  });
}
