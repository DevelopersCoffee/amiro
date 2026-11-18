/// Allow-listed analytics events and property keys (mirrored server-side).
library;

const analyticsEventNames = {
  'setup_complete',
  'first_share',
  'paywall_shown',
  'purchase',
  'second_encounter',
  'invite_sent',
  'export_shared',
};

/// Reserved for install attribution (#62); must match server allow-list.
const analyticsCommunitySlugs = {
  'beta',
  'launch',
  'organic',
};

const analyticsAttributionSources = {'share', 'export', 'store_listing'};

const analyticsPaywallSurfaces = {
  'store_tab',
  'payment_ask',
  'store_item',
};

const analyticsSkuKinds = {'cosmetic', 'plus', 'pack'};

const analyticsCommonKeys = {
  'event',
  'event_day',
  'app_version',
  'platform',
  'install_id',
};

const analyticsOptionalKeys = {
  'surface',
  'sku_kind',
  'community_slug',
  'src',
};

Set<String> allowedKeysForEvent(String event) {
  if (!analyticsEventNames.contains(event)) return {};
  final keys = {...analyticsCommonKeys};
  switch (event) {
    case 'paywall_shown':
      keys.add('surface');
    case 'purchase':
      keys.add('sku_kind');
    default:
      break;
  }
  return keys;
}