/// Whether enabling cloud backup should proceed after consent.
///
/// [showConsentDialog] must run when backup is currently off and the user
/// requests it on. Returns false when the user declines (C7) or when consent
/// was skipped and not accepted (C6).
Future<bool> confirmCloudBackupEnable({
  required bool currentlyEnabled,
  required Future<bool?> Function() showConsentDialog,
}) async {
  if (currentlyEnabled) return true;
  final accepted = await showConsentDialog();
  return accepted == true;
}
