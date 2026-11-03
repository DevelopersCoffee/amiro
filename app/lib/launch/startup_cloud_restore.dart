import 'package:identity_core/identity_core.dart';

/// Mirrors the cold-start branch in `main.dart`: when there is no local
/// identity but cloud backup is on, pull once and save. Never throws.
Future<bool> tryRestoreIdentityFromCloud({
  required Future<Identity?> Function() getCurrent,
  required Future<bool> Function() isBackupEnabled,
  required Future<Identity?> Function() pull,
  required Future<void> Function(Identity identity) save,
}) async {
  try {
    if (await getCurrent() != null) return false;
    if (!await isBackupEnabled()) return false;
    final restored = await pull();
    if (restored == null) return false;
    await save(restored);
    return true;
  } catch (_) {
    return false;
  }
}
