# Encounter share — data that leaves the device

When the user shares via QR or NFC (`amiro://encounter`), the app sends:

## Always included (`AmiroSharingPayload`)

| Field | Purpose |
| --- | --- |
| `remoteIdentityId` | Stable sender id (self-scan detection, passport dedup) |
| `displayName` | Name on the identity card |
| `activeAvatarConfig` | Opaque avatar JSON so the receiver can render the look |

Contact details are **not** in the payload. Public contact fields the user flagged appear only in the optional `c=` contact card parameter (`ContactCard.fromIdentity`).

## Optional (Share tab toggles, default off unless noted)

| Toggle | Default | Wire field |
| --- | --- | --- |
| Equipped cosmetics on card | **On** | `equippedCosmetics` (id, sender-claimed name/rarity/series) |
| Collection progress | **Off** | `collectionCompletion` (per-series owned/total counts) |

Nothing else from the identity profile (email, bio, username, etc.) is embedded unless the user marked it public **and** it fits in the optional contact card.
