import { google } from "googleapis";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../..");
const KEY_FILE = path.join(repo, ".secrets/gcp-play-publisher-key.json");
const PACKAGE_NAME = "com.developerscoffee.amiro_app";
const LANG = "en-US";
const ASSETS = path.join(repo, "docs/store-assets");

const listing = {
  title: "Amiro",
  shortDescription: "Your digital identity, made wearable. Tap or scan to share.",
  fullDescription: `Amiro is your personal digital identity: a 3D avatar you build once and share everywhere.

BUILD YOUR AVATAR
Choose a hairstyle, outfit, and accessories. Rotate it a full 360° to see every angle.

SHARE IT INSTANTLY
Show a QR code, or on Android, tap phones together. Whoever you share with sees your avatar and only the profile details you chose to make public.

YOU CONTROL WHAT'S PUBLIC
Every field in your profile (email, phone, social handles, website) has its own privacy toggle. Fields you mark private never leave your device.

NO ACCOUNT NEEDED
No sign-up and no password. Your identity, avatar, and the people you meet are stored on your device, not on our servers. Uninstalling the app removes them.

COLLECT WHO YOU MEET
Everyone you scan or tap is saved to your Discovery Passport on your device.

A GROWING WARDROBE
Visit the Store for new hairstyles, outfits, and accessories. Many are free; some are optional one-time purchases through Google Play. Purchases are verified with Google Play and our payment provider using an anonymous per-install ID, never your profile details.

Amiro is built for one simple moment: "This is me." Tap or scan, and your digital identity appears.`,
};

const images = {
  icon: ["icon-512.png"],
  featureGraphic: ["feature-graphic.png"],
  phoneScreenshots: [
    "phone-avatar.png",
    "phone-avatar-rotate.png",
    "phone-store.png",
    "phone-share.png",
  ],
};

async function main() {
  if (listing.shortDescription.length > 80) throw new Error("short description > 80");
  if (listing.fullDescription.length > 4000) throw new Error("full description > 4000");

  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const ap = google.androidpublisher({ version: "v3", auth });

  const editId = (await ap.edits.insert({ packageName: PACKAGE_NAME })).data.id;
  console.log("editId:", editId);

  await ap.edits.listings.update({
    packageName: PACKAGE_NAME,
    editId,
    language: LANG,
    requestBody: { language: LANG, ...listing },
  });
  console.log("listing text set");

  for (const [imageType, files] of Object.entries(images)) {
    await ap.edits.images.deleteall({ packageName: PACKAGE_NAME, editId, language: LANG, imageType });
    for (const f of files) {
      await ap.edits.images.upload({
        packageName: PACKAGE_NAME,
        editId,
        language: LANG,
        imageType,
        media: { mimeType: "image/png", body: fs.createReadStream(path.join(ASSETS, f)) },
      });
      console.log(`uploaded ${imageType}: ${f}`);
    }
  }

  await ap.edits.commit({ packageName: PACKAGE_NAME, editId });
  console.log("committed");
}

main().catch((err) => {
  console.error("FAILED:", err.message);
  if (err.response?.data) console.error(JSON.stringify(err.response.data, null, 2));
  process.exit(1);
});
