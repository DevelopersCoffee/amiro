# Manual restore purchases (Pixel / Play internal track)

Device proof for [#52](https://github.com/DevelopersCoffee/amiro/issues/52) and the cross-user rule in [#50](https://github.com/DevelopersCoffee/amiro/issues/50) §6.

Record each run: **date**, **build** (`versionName`/`versionCode` from About or Play), **device**, **Play account email**, **Amiro identity display name**, **result**.

## Owner setup (once per RevenueCat project)

1. In [RevenueCat](https://app.revenuecat.com/) → **Project settings** → **General** → **Restore behavior**, set **Keep with original App User ID** (not “Transfer to new App User ID”). This matches Amiro binding RevenueCat to each Amiro `identity.id` via `Purchases.logIn` in `RevenueCatEntitlementStore`.
2. Optional: enable **Use a different restore behavior for sandbox** only if you need to rehearse transfer behavior without changing production.
3. Confirm entitlements are **RevenueCat-only** (no local unlock flags); paid cosmetics read from `packages/store/lib/src/revenuecat_entitlement_store.dart` only.

## A. Reinstall (same Play account, same Amiro identity)

1. Install internal-track build **1.0.x** with a Play **license tester** account.
2. Open **Store**, buy one paid cosmetic (e.g. Riviera Optics). Confirm the card shows owned (no Buy button).
3. Note the Amiro identity name under **Identity** (do not create a second profile).
4. Uninstall the app (or **Clear storage**).
5. Reinstall the same build, sign into the **same** Play account, restore the **same** Amiro identity from cloud/local if prompted.
6. Open **Store** → **Restore purchases**.
7. **Pass:** snackbar **Purchases restored** (or item already visible); cosmetic stays owned; preview/equip works.
8. **Pass:** no crash; if airplane mode, snackbar **Restore failed** (no crash).

## B. Second device (same Play + same Amiro identity)

1. On the Pixel that still has the purchase from (A), ensure identity A is active.
2. On a second Android device, install the same internal build, same Play tester account.
3. Restore the **same** Amiro identity (cloud backup) so `identity.id` matches the purchasing phone.
4. **Store** → **Restore purchases**.
5. **Pass:** same as (A) — entitlements visible on device 2.

## C. Different Amiro identity, same Play account (must **not** steal purchase)

1. On the purchasing phone, keep Play account **P** signed in.
2. Create or switch to a **second** Amiro identity **B** (new profile, different `identity.id`).
3. **Store** → **Restore purchases**.
4. **Pass:** snackbar mentions **another Amiro identity**; **B** does **not** own the paid cosmetic; Buy button still shows.
5. Switch back to identity **A** that bought the item → restore still works for **A**.

## D. Different Google account on the same phone

1. On the Pixel, add/switch to Play account **Q** (not the buyer).
2. Use Amiro identity **C** (any).
3. **Store** → **Restore purchases**.
4. **Pass:** **No purchases to restore for this account** (or empty owned list), not an ownership conflict.

## Automated coverage (CI)

- `packages/store/test/revenuecat_entitlement_store_test.dart` — restore outcomes + receipt conflict.
- `app/test/store/store_screen_test.dart` — snackbars, cross-user fake, post-restore equip.
- `app/integration_test/restore_purchases_test.dart` — skipped on CI; run on a device with  
  `AMIRO_DEVICE_RESTORE_TEST=1 flutter test integration_test -d <deviceId>`.