import { google } from "googleapis";

const KEY_FILE = new URL("../../.secrets/gcp-play-publisher-key.json", import.meta.url);
const PACKAGE_NAME = "com.developerscoffee.amiro_app";

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE.pathname,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidpublisher = google.androidpublisher({ version: "v3", auth });
  const listed = await androidpublisher.monetization.onetimeproducts.list({
    packageName: PACKAGE_NAME,
    pageSize: 50,
  });
  const products = listed.data.oneTimeProducts ?? [];
  console.log(`one_time_products ${products.length}`);
  for (const product of products) {
    const id = product.productId ?? "unknown";
    const options = product.purchaseOptions ?? [];
    const optionIds = options.map((option) => option.purchaseOptionId ?? "unknown");
    console.log(`product ${id} purchase_options ${optionIds.join(",") || "none"}`);
  }

  const offers = await androidpublisher.monetization.onetimeproducts.purchaseOptions.offers.list({
    packageName: PACKAGE_NAME,
    productId: "-",
    purchaseOptionId: "-",
    pageSize: 100,
  });
  const rows = offers.data.oneTimeProductOffers ?? [];
  console.log(`offers ${rows.length}`);
  console.log("promo_redemption_api unavailable");
}

main().catch((err) => {
  console.error("FAILED:", err.message);
  process.exit(1);
});
