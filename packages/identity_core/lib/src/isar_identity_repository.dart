import 'dart:convert';

import 'package:isar/isar.dart';

import 'identity.dart';
import 'identity_isar_schema.dart';
import 'identity_repository.dart';
import 'privacy_flag.dart';

const _kSingleRowId = 0;

Future<Isar> openIdentityIsar({String? directory}) async {
  // Production entry point. It must NOT call `Isar.initializeIsarCore`.
  // In a real Flutter app, `isar_flutter_libs` already registers the bundled
  // native binary before this runs. This function intentionally has no
  // network-capable fallback so the shipped app never has a runtime
  // code-download path. Pure-Dart test environments (e.g. `dart test`) must
  // call the test-only `initializeIsarCoreForTesting()` helper from
  // `test/test_isar_setup.dart` before invoking this function.
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
      ..avatarDefinitionJson = identity.avatarDefinitionJson
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
      avatarDefinitionJson: record.avatarDefinitionJson,
      privacy: privacyMap,
    );
  }
}
