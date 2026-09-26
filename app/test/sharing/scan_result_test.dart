import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/scan_result.dart';

import '../discovery/support.dart';

void main() {
  test('an encounter link resolves to the decoded card', () {
    final uri = encodeEncounterUri(
      payloadFor(),
      contact: const ContactCard(username: 'ada'),
    );

    final result = resolveScannedText(uri);

    expect(result, isA<EncounterLink>());
    final link = result as EncounterLink;
    expect(link.encounter.payload, payloadFor());
    expect(link.encounter.contact, const ContactCard(username: 'ada'));
  });

  test(
    'a legacy share link from an older build still resolves to a profile',
    () {
      final uri = buildShareUri(
        Identity(id: 'id-1', displayName: 'Ada', username: 'ada'),
      );

      final result = resolveScannedText(uri);

      expect(result, isA<LegacyProfileLink>());
      expect((result as LegacyProfileLink).profile.displayName, 'Ada');
    },
  );

  test('a broken encounter link is invalid, with the reason', () {
    final result = resolveScannedText('amiro://encounter?d=***');

    expect(result, isA<InvalidAmiroLink>());
    expect((result as InvalidAmiroLink).error.kind, PayloadErrorKind.malformed);
  });

  test('an encounter link from a newer schema is invalid, as unsupported', () {
    final uri = encodeEncounterUri(
      payloadFor(),
    ).replaceFirst('?d=', '?d=eyJzY2hlbWFWZXJzaW9uIjoyfQ&x=');

    final result = resolveScannedText(uri);

    expect(result, isA<InvalidAmiroLink>());
    expect(
      (result as InvalidAmiroLink).error.kind,
      PayloadErrorKind.unsupportedVersion,
    );
  });

  test('an amiro link that is neither format is invalid', () {
    expect(
      resolveScannedText('amiro://something-else'),
      isA<InvalidAmiroLink>(),
    );
    expect(
      resolveScannedText('amiro://share?d=not-base64!'),
      isA<InvalidAmiroLink>(),
    );
  });

  test('anything that is not an amiro link is not one', () {
    expect(resolveScannedText('https://example.com'), isA<NotAmiroLink>());
    expect(resolveScannedText(''), isA<NotAmiroLink>());
    expect(resolveScannedText('hello'), isA<NotAmiroLink>());
  });
}
