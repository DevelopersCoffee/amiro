import 'package:amiro_app/sharing/supabase_web_share_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildPublishMergePatch clears revoked_at for rotate', () {
    final body = buildPublishMergePatch(
      token: 'abcdefghijklmnopqrstuvwxy',
      ownerId: 'owner',
      identityId: 'id-1',
      displayName: 'Ada',
      publicContact: const {},
      cardExtras: const {},
      avatarHex: '\\x89504e47',
      updatedAt: '2026-01-01T00:00:00Z',
    );
    expect(body['revoked_at'], isNull);
    expect(body['owner_id'], 'owner');
  });

  test('buildRevokeTombstonePatch wipes public fields', () {
    final body = buildRevokeTombstonePatch('2026-01-01T00:00:00Z');
    expect(body['display_name'], '');
    expect(body['avatar_png'], '\\x');
    expect(body['public_contact'], isEmpty);
    expect(body['revoked_at'], isNotNull);
  });
}