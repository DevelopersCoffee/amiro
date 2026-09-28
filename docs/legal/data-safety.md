# Amiro — Play Console "Data safety" form, draft answers

Fill the actual Play Console form from this. Re-check against the code
before submitting — this reflects the app as of 2026-09-28
(`main`, commit `289788b`); if data handling changes, update both this
file and the live form together.

## Does your app collect or share any of the required user data types?

**Yes** — but only in the sense defined below (see "Is this data
processed ephemerally" / "Is data collection optional" for the actual
nuance). Amiro has no server, so nothing is *collected by the developer*
in Play's usual sense (uploaded off-device). What follows documents what
the app **stores on-device** and **transmits directly device-to-device**
during a share (QR/NFC), since Play's questionnaire asks about handling
broadly, not just server-side collection.

## Data types

### Personal info

| Field | Collected? | Shared? | Processing | Purpose | Optional? |
|---|---|---|---|---|---|
| Name (display name) | Yes | Yes (device-to-device, user-initiated) | On-device only, no server | App functionality | No (required at identity creation) |
| Email address | Yes | Yes, if marked public | On-device only | App functionality | Yes |
| Phone number | Yes | Yes, if marked public | On-device only | App functionality | Yes |
| Other user IDs (username, social handles) | Yes | Yes, if marked public | On-device only | App functionality | Yes |

### Photos or videos

- None. The camera is used transiently to detect a QR code
  (`mobile_scanner`); no image or video is captured, stored, or
  transmitted by the app.

### App activity / App info and performance

- None. No analytics, no crash reporting, no in-app search history, no
  install SDKs.

### Device or other identifiers

- None collected or transmitted. (No advertising ID, no device ID sent
  anywhere — there is nowhere to send it.)

## Is all of the user data collected by your app encrypted in transit?

Not applicable in the usual sense — there is no network transit to
Developer's Coffee. Device-to-device transit (QR/NFC) is answered per
Play's guidance for peer-to-peer sharing features; consult current Play
policy wording for the exact checkbox, since this category evolves.

## Do you provide a way for users to request that their data be deleted?

**Yes** — uninstalling the app deletes all local data. There is no
server-side copy to separately request deletion of, because none exists.
Consider adding an in-app "clear my data" action for a smoother answer
here (not yet implemented — `IdentityRepository.clear()` exists in code
but isn't exposed as a settings/UI action yet).

## Data safety summary line (shown on the store listing)

Suggested Play auto-generated summary should read approximately:
"This app may share... Name, Email address, Phone number... No data
collected" is NOT quite right since data IS collected (locally) — work
through Play's actual flow carefully, since "collected" in their taxonomy
includes on-device storage in some cases and not others depending on how
each question is phrased. This file is a starting draft, not a substitute
for reading each Play Console question directly against the current app.
