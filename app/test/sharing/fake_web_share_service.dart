import 'dart:typed_data';

import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/sharing/encounter_share_options.dart';
import 'package:amiro_app/sharing/supabase_web_share_client.dart';
import 'package:sharing/sharing.dart';

class FakeWebShareService implements WebShareService {
  FakeWebShareService({
    this.canPublish = true,
    this.publishToken = 'testtokenabcdefghij',
  });

  @override
  final bool canPublish;

  String publishToken;
  int publishCalls = 0;
  int revokeCalls = 0;
  bool revokeResult = true;

  @override
  Future<WebSharePublishResult> publish({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    Uint8List? avatarPng,
    String? existingToken,
  }) async {
    publishCalls += 1;
    return WebSharePublishResult.success(publishToken);
  }

  @override
  Future<WebSharePublishResult> rotate({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    required String existingToken,
    Uint8List? avatarPng,
  }) {
    publishToken = generateWebShareToken();
    return publish(
      identity: identity,
      definition: definition,
      purchasedIds: purchasedIds,
      shareOptions: shareOptions,
      existingToken: existingToken,
      avatarPng: avatarPng,
    );
  }

  @override
  Future<bool> revoke({required String token}) async {
    revokeCalls += 1;
    return revokeResult;
  }

  @override
  String buildPublicUri(String token) => buildWebShareUri(token);
}