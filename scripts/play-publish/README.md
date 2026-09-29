# play-publish

Scripts that talk to the Google Play Developer API directly — the route
that actually works, since Play Console's upload widget needs a native OS
file picker no browser-automation tool here can drive, and a 107MB release
bundle is over the 10MB cap on the one in-chat upload tool that can bypass
the picker.

## Setup

Both scripts expect the service account key at
`../../.secrets/gcp-play-publisher-key.json` (gitignored, never commit it).
That key belongs to `amiro-play-publisher@developerscoffee.iam.gserviceaccount.com`
— created in GCP project `developerscoffee`, invited in Play Console
(Users and permissions) with **Release apps to testing tracks**, **Manage
testing tracks and edit tester lists**, and **Manage store presence** on
the Amiro app only. Deliberately does *not* have "Release to production" —
that's a separate, higher-stakes grant to add explicitly when you're ready
to actually ship to real users.

```bash
npm install
```

## upload.mjs

Uploads `app/build/app/outputs/bundle/release/app-release.aab` and
publishes it to the `internal` testing track. Bump
`app/pubspec.yaml`'s version code before building a new release, then:

```bash
npm run upload
```

## create_products.mjs

Upserts the 3 paid Store catalog items as Play Console one-time products
(`monetization.onetimeproducts.patch` with `allowMissing: true`), matching
the RevenueCat catalog (`workers/revenuecat-webhook/README.md`). As of
2026-09-29 this fails with a 403 even though reads with the same key
succeed — the "Manage store presence" grant hadn't propagated to Google's
write-path backends yet. Retry it; no changes needed if it was just
propagation lag.

```bash
npm run create-products
```
