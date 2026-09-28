import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/own_encounter.dart';

void main() {
  final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
  const definition = AvatarDefinition(
    id: 'default',
    body: 'body_superhero_male',
    hair: 'hair_simple_parted', // clean_part: free, common, no series
    glasses: 'glasses_realistic', // riviera_optics: rare, Series #1
  );

  group('buildOwnEncounterPayload', () {
    test('identifies the sender by their identity id and display name', () {
      final payload = buildOwnEncounterPayload(
        identity: identity,
        definition: definition,
        purchasedIds: const {},
      )!;

      expect(payload.remoteIdentityId, 'id-1');
      expect(payload.displayName, 'Uday');
    });

    test('lists equipped catalog items with wire rarity and series id', () {
      final payload = buildOwnEncounterPayload(
        identity: identity,
        definition: definition,
        purchasedIds: const {},
      )!;

      final byId = {for (final c in payload.equippedCosmetics) c.id: c};
      expect(byId['riviera_optics']!.name, 'Riviera Optics');
      expect(byId['riviera_optics']!.rarity, 'RARE');
      expect(byId['riviera_optics']!.seriesId, 'series_1');
      expect(byId['clean_part']!.rarity, 'COMMON');
      expect(byId['clean_part']!.seriesId, isNull);
    });

    test(
      'leaves out equipped assets that are not in the catalog (the body)',
      () {
        final payload = buildOwnEncounterPayload(
          identity: identity,
          definition: definition,
          purchasedIds: const {},
        )!;

        expect(
          payload.equippedCosmetics.map((c) => c.id),
          isNot(contains('body_superhero_male')),
        );
        expect(payload.equippedCosmetics, hasLength(2));
      },
    );

    test('reports series completion from purchases', () {
      final payload = buildOwnEncounterPayload(
        identity: identity,
        definition: definition,
        purchasedIds: const {'riviera_optics'},
      )!;

      final series = payload.collectionCompletion.singleWhere(
        (s) => s.seriesId == 'series_1',
      );
      expect(series.currentCount, 1);
      expect(series.totalCount, 3);
    });

    test('carries the avatar definition as JSON', () {
      final payload = buildOwnEncounterPayload(
        identity: identity,
        definition: definition,
        purchasedIds: const {},
      )!;

      expect(jsonDecode(payload.activeAvatarConfig), definition.toJson());
    });

    test(
      'falls back to the identity\'s persisted avatar when nothing is loaded',
      () {
        final withAvatar = Identity(
          id: 'id-1',
          displayName: 'Uday',
          username: 'uday',
          avatarDefinitionJson: '{"id":"saved","body":"body_superhero_male"}',
        );

        final payload = buildOwnEncounterPayload(
          identity: withAvatar,
          definition: null,
          purchasedIds: const {},
        )!;

        expect(
          payload.activeAvatarConfig,
          '{"id":"saved","body":"body_superhero_male"}',
        );
      },
    );

    test('is null until the user has an avatar at all', () {
      expect(
        buildOwnEncounterPayload(
          identity: identity,
          definition: null,
          purchasedIds: const {},
        ),
        isNull,
      );
    });

    test('always produces a payload that encodes', () {
      final payload = buildOwnEncounterPayload(
        identity: identity,
        definition: definition,
        purchasedIds: const {'riviera_optics', 'long_flow', 'full_beard'},
      )!;

      expect(payload.encode, returnsNormally);
    });
  });

  group('progressFromCompletion', () {
    test('resolves known series and skips ones this app does not know', () {
      final progress = progressFromCompletion(const [
        SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
        SeriesCompletion(seriesId: 'series_99', currentCount: 1, totalCount: 1),
      ]);

      expect(progress, hasLength(1));
      expect(progress.single.series.number, 1);
      expect(progress.single.owned, 2);
      expect(progress.single.total, 3);
    });
  });

  group('buildOwnEncounterUri', () {
    test('is a decodable encounter link carrying the public contact card', () {
      final shared = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Engineer',
        privacy: const {'username': PrivacyFlag(true)},
      );

      final uri = buildOwnEncounterUri(identity: shared, definition: definition, purchasedIds: const {});
      final decoded = decodeEncounterUri(uri!);

      expect(decoded.payload.remoteIdentityId, 'id-1');
      expect(decoded.contact, const ContactCard(username: 'uday'));
    });

    test('is null until the user has an avatar', () {
      expect(buildOwnEncounterUri(identity: identity, definition: null, purchasedIds: const {}), isNull);
    });

    test('drops only the contact card when it is what makes the link too large', () {
      final wordy = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'b' * 256,
        email: 'e' * 256,
        mobile: 'm' * 256,
        xHandle: 'x' * 256,
        instagramHandle: 'i' * 256,
        website: 'w' * 256,
        privacy: const {
          'bio': PrivacyFlag(true),
          'email': PrivacyFlag(true),
          'mobile': PrivacyFlag(true),
          'xHandle': PrivacyFlag(true),
          'instagramHandle': PrivacyFlag(true),
          'website': PrivacyFlag(true),
        },
      );

      final uri = buildOwnEncounterUri(identity: wordy, definition: definition, purchasedIds: const {});

      expect(uri, isNotNull);
      final decoded = decodeEncounterUri(uri!);
      expect(decoded.payload.displayName, 'Uday');
      expect(decoded.contact, isNull);
    });
  });
}
