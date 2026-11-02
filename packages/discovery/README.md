# discovery

Encounter ledger and state machine for the Passport tab.

- **`EncounterRecord`**, **`DiscoveryRepository`**
  (`FileDiscoveryRepository` persists to `discovery.json` under app support).
- **`EncounterProcessor`** — two-phase receive vs save; classifies new/known/self
  encounters before anything is written.

Wired from `app/lib/discovery/` (Passport screen, encounter comparison).
Sharing payloads reach this package only after `packages/sharing` validates
them (`AmiroSharingPayload`).
