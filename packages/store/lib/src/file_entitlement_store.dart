import 'dart:convert';
import 'dart:io';

import 'entitlement_store.dart';

/// Persists owned cosmetic ids as a JSON array in a single file — matches
/// the product's local-first architecture (no backend round-trip needed to
/// know what a user owns). Concurrent writers aren't a concern: this store
/// is only ever touched by the app's own UI thread, one purchase at a time.
class FileEntitlementStore implements EntitlementStore {
  final File _file;

  FileEntitlementStore(this._file);

  @override
  Future<Set<String>> ownedCosmeticIds() async {
    if (!await _file.exists()) return const {};
    final contents = await _file.readAsString();
    if (contents.trim().isEmpty) return const {};
    final ids = (jsonDecode(contents) as List).cast<String>();
    return ids.toSet();
  }

  @override
  Future<void> grant(String cosmeticId) async {
    final owned = await ownedCosmeticIds();
    if (owned.contains(cosmeticId)) return;
    final updated = {...owned, cosmeticId};
    await _file.create(recursive: true);
    await _file.writeAsString(jsonEncode(updated.toList()));
  }
}
