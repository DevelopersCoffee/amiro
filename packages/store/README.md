# store

**Status: stub — not implemented.**

Owns the cosmetic catalog, ownership/entitlement records, and platform
purchase flows (StoreKit / Play Billing). Planned interface:

- `Future<List<CosmeticListing>> fetchCatalog()`
- `Future<PurchaseResult> purchase(String cosmeticId)`
- `Future<Set<String>> ownedCosmeticIds()`

Implemented in a future milestone (M3, Cosmetics), by the Payments and
Backend agents. No custom payment system — platform-native purchase
APIs only, per the PRD's Monetization section.
