import 'package:isar/isar.dart';

/// Test-only Isar native-binary bootstrap.
///
/// In a pure-Dart context (e.g. `dart test`), the Isar native binary isn't
/// auto-registered the way `isar_flutter_libs` does for a running Flutter
/// app. This helper fetches the right binary for this platform once and
/// caches it, so tests can open Isar databases without a Flutter host.
///
/// This lives under `test/`, not `lib/`, and is deliberately NOT exported
/// from `identity_core.dart`. Production code (including
/// `openIdentityIsar()` in `lib/src/isar_identity_repository.dart`) must
/// never call `Isar.initializeIsarCore(download: true)` — that would give
/// the shipped app a network-capable fallback path, which this package's
/// "no network calls in the shipped app" constraint forbids.
Future<void> initializeIsarCoreForTesting() async {
  await Isar.initializeIsarCore(download: true);
}
