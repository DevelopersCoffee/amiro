import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:identity_core/identity_core.dart';

class RecordingProfileCloud implements ProfileCloud {
  RecordingProfileCloud({this.supportsRestoreValue = true});

  final bool supportsRestoreValue;
  int pushCalls = 0;
  int revokeCalls = 0;
  Identity? lastPushed;
  RevokeBackupResult revokeResult = const RevokeBackupResult.ok();

  @override
  bool get supportsRestore => supportsRestoreValue;

  @override
  Future<String?> recoveryCode() async => 'recovery-code-1234567890ab';

  @override
  Future<bool> push(Identity identity) async {
    pushCalls += 1;
    lastPushed = identity;
    return true;
  }

  @override
  Future<Identity?> pull() async => null;

  @override
  Future<Identity?> claim(String code) async => null;

  @override
  Future<RevokeBackupResult> revokeBackup({String? identityId}) async {
    revokeCalls += 1;
    return revokeResult;
  }
}
