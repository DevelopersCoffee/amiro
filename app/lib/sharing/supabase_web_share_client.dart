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
    String? existingToken,
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
    String? existingToken,
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

    final token = generateWebShareToken();
    final contact = ContactCard.fromIdentity(identity);
    final png = stripAvatarMetadata(
      avatarPng ?? buildFallbackWebShareAvatar(identity.displayName),
    );
    final extras = <String, dynamic>{
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

    try {
      final session = await _cloud.userSessionForDataPlane();
      final updatedAt = DateTime.now().toUtc().toIso8601String();
      final body = jsonEncode(buildPublishMergePatch(
        token: token,
        ownerId: session.userId,
        identityId: identity.id,
        displayName: identity.displayName,
        publicContact: contact.toJson(),
        cardExtras: extras,
        avatarHex: _byteaHex(png),
        updatedAt: updatedAt,
      ));
      if (existingToken != null && existingToken.isNotEmpty) {
        await revoke(token: existingToken);
      }
      final response = await _cloud.sendAuthenticated(
        method: 'POST',
        uri: _cloud.restTable('web_share_profiles').replace(
          queryParameters: {'on_conflict': 'owner_id'},
        ),
        accessToken: session.accessToken,
        extraHeaders: const {'Prefer': 'resolution=merge-duplicates'},
        body: body,
      );
      if (response.status >= 200 && response.status < 300) {
        return WebSharePublishResult.success(token);
      }
      return await _patchByOwner(
        ownerId: session.userId,
        token: token,
        identityId: identity.id,
        contact: contact,
        extras: extras,
        png: png,
        displayName: identity.displayName,
      );
    } catch (_) {
      return const WebSharePublishResult.failure('Publish failed');
    }
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
    return publish(
      identity: identity,
      definition: definition,
      purchasedIds: purchasedIds,
      shareOptions: shareOptions,
      avatarPng: avatarPng,
      existingToken: existingToken,
    );
  }

  Future<WebSharePublishResult> _patchByOwner({
    required String ownerId,
    required String token,
    required String identityId,
    required ContactCard contact,
    required Map<String, dynamic> extras,
    required Uint8List png,
    required String displayName,
  }) async {
    final session = await _cloud.userSessionForDataPlane();
    final response = await _cloud.sendAuthenticated(
      method: 'PATCH',
      uri: _cloud.restTable('web_share_profiles').replace(
        queryParameters: {'owner_id': 'eq.$ownerId'},
      ),
      accessToken: session.accessToken,
      body: jsonEncode({
        'token': token,
        'identity_id': identityId,
        'display_name': displayName,
        'public_contact': contact.toJson(),
        'card_extras': extras,
        'avatar_png': _byteaHex(png),
        'revoked_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.status >= 200 && response.status < 300) {
      return WebSharePublishResult.success(token);
    }
    return WebSharePublishResult.failure('Publish failed (${response.status})');
  }

  @override
  Future<bool> revoke({required String token}) async {
    if (!canPublish) return false;
    try {
      final session = await _cloud.userSessionForDataPlane();
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _cloud.sendAuthenticated(
        method: 'PATCH',
        uri: _cloud.restTable('web_share_profiles').replace(
          queryParameters: {'token': 'eq.$token'},
        ),
        accessToken: session.accessToken,
        body: jsonEncode(buildRevokeTombstonePatch(now)),
      );
      return response.status >= 200 && response.status < 300;
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

@visibleForTesting
Map<String, dynamic> buildPublishMergePatch({
  required String token,
  required String ownerId,
  required String identityId,
  required String displayName,
  required Map<String, dynamic> publicContact,
  required Map<String, dynamic> cardExtras,
  required String avatarHex,
  required String updatedAt,
}) {
  return {
    'token': token,
    'owner_id': ownerId,
    'identity_id': identityId,
    'display_name': displayName,
    'public_contact': publicContact,
    'card_extras': cardExtras,
    'avatar_png': avatarHex,
    'revoked_at': null,
    'updated_at': updatedAt,
  };
}