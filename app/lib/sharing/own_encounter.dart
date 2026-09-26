import 'dart:convert';

import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

/// The identity card the user shows others, as the canonical
/// [AmiroSharingPayload]: who they are, what they have equipped, how far
/// through each series they are. Null until they have an avatar to show.
///
/// [definition] is the live avatar when one is loaded; otherwise the
/// identity's persisted one is used. Equipped assets that are not in the
/// catalog (the body, an unlisted item) are left out.
AmiroSharingPayload? buildOwnEncounterPayload({
  required Identity identity,
  required AvatarDefinition? definition,
  required Set<String> purchasedIds,
}) {
  final persisted = identity.avatarDefinitionJson;
  final AvatarDefinition equipped;
  final String config;
  if (definition != null) {
    equipped = definition;
    config = jsonEncode(definition.toJson());
  } else if (persisted != null) {
    try {
      equipped = AvatarDefinition.fromJson(
        jsonDecode(persisted) as Map<String, dynamic>,
      );
    } catch (_) {
      return null; // a corrupt saved avatar is not something to put on a card
    }
    config = persisted;
  } else {
    return null;
  }

  final byAssetId = {for (final item in cosmeticCatalog) item.assetId: item};
  final json = equipped.toJson();
  final cosmetics = <EquippedCosmeticInfo>[];
  for (final slot in AvatarDefinition.slots) {
    final listing = byAssetId[json[slot]];
    if (listing == null) continue;
    cosmetics.add(
      EquippedCosmeticInfo(
        id: listing.id,
        name: listing.name,
        seriesId: listing.series?.id,
        rarity: listing.rarity.wireName,
      ),
    );
  }

  return AmiroSharingPayload(
    remoteIdentityId: identity.id,
    displayName: identity.displayName,
    activeAvatarConfig: config,
    equippedCosmetics: cosmetics,
    collectionCompletion: [
      for (final progress in collectionProgress(cosmeticCatalog, purchasedIds))
        SeriesCompletion(
          seriesId: progress.series.id,
          currentCount: progress.owned,
          totalCount: progress.total,
        ),
    ],
  );
}

/// [completion] resolved against this app's catalog, for display. Series
/// this version does not know are skipped rather than guessed at.
List<CollectionProgress> progressFromCompletion(
  List<SeriesCompletion> completion,
) {
  final seriesById = {
    for (final item in cosmeticCatalog)
      if (item.series != null) item.series!.id: item.series!,
  };
  return [
    for (final entry in completion)
      if (seriesById[entry.seriesId] case final series?)
        CollectionProgress(
          series: series,
          owned: entry.currentCount,
          total: entry.totalCount,
        ),
  ];
}

/// The link behind this user's QR code and NFC tag: their card plus the
/// public contact fields they chose to share. Null until they have an avatar
/// or if the card cannot be made small enough for a QR code.
///
/// If the contact card is what pushes the link over the size limit, the link
/// is built without it: sharing who they are matters more than failing to
/// share at all, and the contact fields are optional decoration.
String? buildOwnEncounterUri({
  required Identity identity,
  required AvatarDefinition? definition,
  required Set<String> purchasedIds,
}) {
  final payload = buildOwnEncounterPayload(
    identity: identity,
    definition: definition,
    purchasedIds: purchasedIds,
  );
  if (payload == null) return null;

  try {
    return encodeEncounterUri(
      payload,
      contact: ContactCard.fromIdentity(identity),
    );
  } on SharingPayloadException catch (e) {
    if (e.kind != PayloadErrorKind.tooLarge) return null;
  }
  try {
    return encodeEncounterUri(payload);
  } on SharingPayloadException {
    return null;
  }
}
