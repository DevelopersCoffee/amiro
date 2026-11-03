import 'package:amiro_app/identity/cloud_backup_enable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C7: decline does not confirm enable', () async {
    final ok = await confirmCloudBackupEnable(
      currentlyEnabled: false,
      showConsentDialog: () async => false,
    );
    expect(ok, isFalse);
  });

  test('C6: enable requires explicit accept', () async {
    var shown = false;
    final declined = await confirmCloudBackupEnable(
      currentlyEnabled: false,
      showConsentDialog: () async {
        shown = true;
        return null;
      },
    );
    expect(shown, isTrue);
    expect(declined, isFalse);
  });

  test('accept confirms enable', () async {
    final ok = await confirmCloudBackupEnable(
      currentlyEnabled: false,
      showConsentDialog: () async => true,
    );
    expect(ok, isTrue);
  });

  test('already enabled skips dialog', () async {
    var shown = false;
    final ok = await confirmCloudBackupEnable(
      currentlyEnabled: true,
      showConsentDialog: () async {
        shown = true;
        return false;
      },
    );
    expect(ok, isTrue);
    expect(shown, isFalse);
  });
}
