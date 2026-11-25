# Backup deletion — owner decisions O1 and O2

**Status:** Pending. No behavior change in this pass. Current `origin/main`
behavior is what ships.

## What the app does today

Cloud backup is opt-in (`cloud_backup_consent_dialog.dart`). Turning it off
calls `SupabaseProfileCloud.revokeBackup`, which `DELETE`s the `profiles` row
for the current anonymous session when that session is the owner
(`20261102100000_profiles_delete_owner.sql`). A successful delete also removes
that user's `web_share_profiles` rows and clears the on-device recovery code
and session.

Strings when the server row is not deleted:

- Zero rows deleted, row still visible: "Only the device that created the
  backup can remove the cloud copy, or the copy was already removed."
- Empty select but this device cannot prove the row is gone (recovery code
  present, owner id missing or mismatched): "This device cannot remove the
  cloud backup copy. If sign-in on this device no longer matches the account
  that enabled backup, request deletion by email as described in the privacy
  policy."
- Other failures use the generic revoke failure path. The UI does not say the
  backup was deleted.

Cases that hit those errors: a member device that joined with the recovery
code, a session swap on the same phone, a legacy install with no stored owner
id, or a row that is already gone when the session cannot prove it.

## O1 — what to show when server delete is impossible

**Not chosen.** Do not change member-device revoke behavior until the owner
picks one:

1. Keep the honest errors above (current).
2. Add a local-only "stop backing up on this device" that clears credentials
   without claiming the server row was deleted.

## O2 — `delete_profile(p_code)` vs email

**Not chosen.** Do not add a `SECURITY DEFINER` RPC that deletes by recovery
code unless the owner approves it.

| Option | Effect |
|---|---|
| Email only (current policy) | Owner session can DELETE under RLS. Everyone else emails coffee.devloper@gmail.com. No new privilege. |
| `delete_profile(p_code)` | Lets a device that knows the recovery code delete the row even when its auth user is not the owner. Bypasses the owner-only RLS policy. The privacy policy would have to say possession of the code is enough to delete the cloud copy. |

Until O2 is approved, the policy stays email-only for stranded copies.
