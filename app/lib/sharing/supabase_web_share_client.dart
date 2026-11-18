import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import '../identity/supabase_profile_cloud.dart';
import '../identity/supabase_public.dart';
import 'own_encounter.dart';
import 'web_share_avatar_image.dart';
import 'encounter_share_options.dart';

abstract class WebShareService {
  bool get canPublish;
  Future<WebSharePublishResult> publish({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    Uint8List? avatarPng,
  });
  Future<WebSharePublishResult> rotate({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    required String existingToken,
    Uint8List? avatarPng,
  });
  Future<bool> revoke({required String token});
  String buildPublicUri(String token);
}

class WebSharePublishResult {
  const WebSharePublishResult.success(this.token) : error = null;
  const WebSharePublishResult.failure(this.error) : token = null;

  final String? token;
  final String? error;

  bool get ok => token != null;
}

class SupabaseWebShareClient implements WebShareService {
  SupabaseWebShareClient(this._cloud);

  final SupabaseProfileCloud _cloud;

  @override
  bool get canPublish => _cloud.supportsRestore;

  @override
  Future<WebSharePublishResult> publish({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    Uint8List? avatarPng,
  }) async {
    return _mutateProfile(
      rpcName: 'web_share_publish',
      identity: identity,
      definition: definition,
      purchasedIds: purchasedIds,
      shareOptions: shareOptions,
      avatarPng: avatarPng,
    );
  }

  @override
  Future<WebSharePublishResult> rotate({
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    required String existingToken,
    Uint8List? avatarPng,
  }) async {
    return _mutateProfile(
      rpcName: 'web_share_rotate',
      identity: identity,
      definition: definition,
      purchasedIds: purchasedIds,
      shareOptions: shareOptions,
      avatarPng: avatarPng,
      oldToken: existingToken,
    );
  }

  Future<WebSharePublishResult> _mutateProfile({
    required String rpcName,
    required Identity identity,
    required AvatarDefinition? definition,
    required Set<String> purchasedIds,
    required EncounterShareOptions shareOptions,
    Uint8List? avatarPng,
    String? oldToken,
  }) async {
    if (!canPublish) {
      return const WebSharePublishResult.failure('Web share is not configured');
    }
    final payload = buildOwnEncounterPayload(
      identity: identity,
      definition: definition,
      purchasedIds: purchasedIds,
      shareOptions: shareOptions,
    );
    if (payload == null) {
      return const WebSharePublishResult.failure('Avatar not ready');
    }

    final contact =
        filterWebSharePublicContact(ContactCard.fromIdentity(identity).toJson());
    final png = stripAvatarMetadata(
      avatarPng ?? buildFallbackWebShareAvatar(identity.displayName),
    );
    final extras = filterWebShareCardExtras(_cardExtras(payload, shareOptions));

    try {
      final session = await _cloud.userSessionForDataPlane();
      final body = jsonEncode(buildWebShareRpcBody(
        identityId: identity.id,
        displayName: identity.displayName,
        publicContact: contact,
        cardExtras: extras,
        avatarHex: _byteaHex(png),
        oldToken: oldToken,
      ));
      final response = await _cloud.sendAuthenticated(
        method: 'POST',
        uri: _cloud.restRpc(rpcName),
        accessToken: session.accessToken,
        extraHeaders: const {'Prefer': 'return=representation'},
        body: body,
      );
      final token = parseWebShareRpcToken(response.status, response.body);
      if (token != null) {
        return WebSharePublishResult.success(token);
      }
      return WebSharePublishResult.failure(
        'Publish failed (${response.status})',
      );
    } catch (_) {
      return const WebSharePublishResult.failure('Publish failed');
    }
  }

  Map<String, dynamic> _cardExtras(
    AmiroSharingPayload payload,
    EncounterShareOptions shareOptions,
  ) {
    return {
      if (shareOptions.includeEquippedCosmetics)
        'equippedCosmetics': payload.equippedCosmetics
            .map((c) => {'name': c.name, 'rarity': c.rarity})
            .toList(),
      if (shareOptions.includeCollectionProgress)
        'collectionCompletion': payload.collectionCompletion
            .map(
              (s) => {
                'seriesId': s.seriesId,
                'currentCount': s.currentCount,
                'totalCount': s.totalCount,
              },
            )
            .toList(),
    };
  }

  @override
  Future<bool> revoke({required String token}) async {
    if (!canPublish) return false;
    try {
      final session = await _cloud.userSessionForDataPlane();
      final response = await _cloud.sendAuthenticated(
        method: 'POST',
        uri: _cloud.restRpc('web_share_revoke'),
        accessToken: session.accessToken,
        extraHeaders: const {'Prefer': 'return=representation'},
        body: jsonEncode({'p_token': token}),
      );
      return parseWebShareRpcToken(response.status, response.body) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  String buildPublicUri(String token) =>
      buildWebShareUri(token, host: webSharePublicHost);
}

String _byteaHex(Uint8List bytes) {
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '\\x$hex';
}

@visibleForTesting
Map<String, dynamic> buildWebShareRpcBody({
  required String identityId,
  required String displayName,
  required Map<String, dynamic> publicContact,
  required Map<String, dynamic> cardExtras,
  required String avatarHex,
  String? oldToken,
}) {
  return {
    'p_identity_id': identityId,
    'p_display_name': displayName,
    'p_public_contact': publicContact,
    'p_card_extras': cardExtras,
    'p_avatar_png': avatarHex,
    if (oldToken != null) 'p_old_token': oldToken,
  };
}

@visibleForTesting
String? parseWebShareRpcToken(int status, String body) {
  if (status == 204 || body.isEmpty) return null;
  if (status < 200 || status >= 300) return null;
  try {
    final decoded = jsonDecode(body);
    final Map<String, dynamic>? row;
    if (decoded is Map<String, dynamic>) {
      row = decoded;
    } else if (decoded is List && decoded.length == 1) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        row = first;
      }
    }
    final token = row?['token'];
    if (token is String && token.length >= 22) {
      return token;
    }
  } catch (_) {}
  return null;
}

@visibleForTesting
Map<String, dynamic> buildRevokeTombstonePatch(String revokedAtIso) {
  return {
    'revoked_at': revokedAtIso,
    'updated_at': revokedAtIso,
    'display_name': '',
    'public_contact': <String, dynamic>{},
    'card_extras': <String, dynamic>{},
    'avatar_png': '\\x',
  };
}