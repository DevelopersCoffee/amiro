import { google } from "googleapis";

const KEY_FILE = "/Users/udaychauhan/workspace/amiro/.secrets/gcp-play-publisher-key.json";
const PACKAGE_NAME = "com.developerscoffee.amiro_app";
const REGIONS_VERSION = "2022/02";

const PRODUCTS = [
  {
    productId: "amiro_riviera_optics",
    title: "Riviera Optics",
    description: "Rare glasses cosmetic for your Amiro avatar (Series #1 Founders).",
    units: "2",
    nanos: 990000000,
  },
  {
    productId: "amiro_long_flow",
    title: "Long Flow",
    description: "Uncommon hair cosmetic for your Amiro avatar (Series #1 Founders).",
    units: "1",
    nanos: 990000000,
  },
  {
    productId: "amiro_full_beard",
    title: "Full Beard",
    description: "Uncommon facial hair cosmetic for your Amiro avatar (Series #1 Founders).",
    units: "0",
    nanos: 990000000,
  },
];

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidpublisher = google.androidpublisher({ version: "v3", auth });

  for (const p of PRODUCTS) {
    console.log(`Upserting ${p.productId}...`);
    try {
      const res = await androidpublisher.monetization.onetimeproducts.patch({
        packageName: PACKAGE_NAME,
        productId: p.productId,
        allowMissing: true,
        "regionsVersion.version": REGIONS_VERSION,
        updateMask: "listings,purchaseOptions",
        requestBody: {
          packageName: PACKAGE_NAME,
          productId: p.productId,
          listings: [
            {
              languageCode: "en-US",
              title: p.title,
              description: p.description,
            },
          ],
          purchaseOptions: [
            {
              purchaseOptionId: "buy",
              buyOption: {},
              regionalPricingAndAvailabilityConfigs: [
                {
                  regionCode: "US",
                  availability: "AVAILABLE",
                  price: {
                    currencyCode: "USD",
                    units: p.units,
                    nanos: p.nanos,
                  },
                },
              ],
              newRegionsConfig: {
                availability: "AVAILABLE",
                usdPrice: {
                  currencyCode: "USD",
                  units: p.units,
                  nanos: p.nanos,
                },
                eurPrice: {
                  currencyCode: "EUR",
                  units: p.units,
                  nanos: p.nanos,
                },
              },
            },
          ],
        },
      });
      console.log("  ok:", res.data.productId);
    } catch (err) {
      console.error(`  FAILED ${p.productId}:`, err.message);
      if (err.response?.data) console.error(JSON.stringify(err.response.data, null, 2));
    }
  }
}

main();
