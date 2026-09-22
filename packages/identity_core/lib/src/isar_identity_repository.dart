import 'dart:convert';

import 'package:isar/isar.dart';

import 'identity.dart';
import 'identity_isar_schema.dart';
import 'identity_repository.dart';
import 'privacy_flag.dart';

const _kSingleRowId = 0;

Future<Isar> openIdentityIsar({String? directory}) async {
  // In a pure-Dart context (e.g. `dart test`), the Isar native binary isn't
  // auto-registered the way `isar_flutter_libs` does for a running Flutter
  // app. Isar resolves this itself: if the binary isn't already reachable
  // next to the script, it fetches the right one for this platform once and
  // caches it there. This is a no-op inside a real Flutter app, where
  // `isar_flutter_libs` already ships the binary.
  await Isar.initializeIsarCore(download: true);
  return Isar.open(
    [IdentityRecordSchema],
    directory: directory ?? '.',
  );
}

class IsarIdentityRepository implements IdentityRepository {
  final Isar _isar;

  IsarIdentityRepository(this._isar);

  @override
  Future<Identity?> getCurrent() async {
    final record = await _isar.identityRecords.get(_kSingleRowId);
    if (record == null) return null;
    return _toIdentity(record);
  }

  @override
  Future<void> save(Identity identity) async {
    final record = _toRecord(identity);
    await _isar.writeTxn(() => _isar.identityRecords.put(record));
  }

  @override
  Future<void> clear() async {
    await _isar.writeTxn(() => _isar.identityRecords.delete(_kSingleRowId));
  }

  IdentityRecord _toRecord(Identity identity) {
    final privacyMap = identity.privacy.map((k, v) => MapEntry(k, v.isPublic));
    return IdentityRecord()
      ..isarId = _kSingleRowId
      ..id = identity.id
      ..displayName = identity.displayName
      ..username = identity.username
      ..bio = identity.bio
      ..mobile = identity.mobile
      ..email = identity.email
      ..xHandle = identity.xHandle
      ..instagramHandle = identity.instagramHandle
      ..website = identity.website
      ..avatarDefinitionId = identity.avatarDefinitionId
      ..privacyJson = jsonEncode(privacyMap);
  }

  Identity _toIdentity(IdentityRecord record) {
    final privacyMap = (jsonDecode(record.privacyJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, PrivacyFlag(v as bool)));
    return Identity(
      id: record.id,
      displayName: record.displayName,
      username: record.username,
      bio: record.bio,
      mobile: record.mobile,
      email: record.email,
      xHandle: record.xHandle,
      instagramHandle: record.instagramHandle,
      website: record.website,
      avatarDefinitionId: record.avatarDefinitionId,
      privacy: privacyMap,
    );
  }
}
