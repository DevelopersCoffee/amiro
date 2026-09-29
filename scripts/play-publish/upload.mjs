import { google } from "googleapis";
import fs from "fs";

const KEY_FILE = "/Users/udaychauhan/workspace/amiro/.secrets/gcp-play-publisher-key.json";
const PACKAGE_NAME = "com.developerscoffee.amiro_app";
const AAB_PATH = "/Users/udaychauhan/workspace/amiro/app/build/app/outputs/bundle/release/app-release.aab";
const TRACK = "internal";

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidpublisher = google.androidpublisher({ version: "v3", auth });

  console.log("Creating edit...");
  const edit = await androidpublisher.edits.insert({ packageName: PACKAGE_NAME });
  const editId = edit.data.id;
  console.log("editId:", editId);

  console.log("Uploading bundle (this may take a minute for 107MB)...");
  const bundle = await androidpublisher.edits.bundles.upload(
    {
      packageName: PACKAGE_NAME,
      editId,
      media: {
        mimeType: "application/octet-stream",
        body: fs.createReadStream(AAB_PATH),
      },
    },
    {
      // 107MB upload, default axios timeout is too short
      timeout: 10 * 60 * 1000,
    },
  );
  const versionCode = bundle.data.versionCode;
  console.log("Uploaded, versionCode:", versionCode);

  console.log(`Assigning to ${TRACK} track...`);
  await androidpublisher.edits.tracks.update({
    packageName: PACKAGE_NAME,
    editId,
    track: TRACK,
    requestBody: {
      track: TRACK,
      releases: [
        {
          versionCodes: [String(versionCode)],
          status: "completed",
        },
      ],
    },
  });

  console.log("Committing edit...");
  const commit = await androidpublisher.edits.commit({
    packageName: PACKAGE_NAME,
    editId,
  });
  console.log("Committed. Edit id:", commit.data.id);
  console.log("DONE — versionCode", versionCode, "live on", TRACK, "track.");
}

main().catch((err) => {
  console.error("FAILED:", err.message);
  if (err.errors) console.error(JSON.stringify(err.errors, null, 2));
  if (err.response?.data) console.error(JSON.stringify(err.response.data, null, 2));
  process.exit(1);
});
