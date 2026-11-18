import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';
import '../discovery/discovery_providers.dart';
import 'analytics_once.dart';
import 'analytics_providers.dart';
import 'analytics_service.dart';

/// High-level funnel events (consent + once-per-install guards).
class AnalyticsFunnel {
  AnalyticsFunnel(this._ref);

  final Ref _ref;

  AnalyticsOnceStore get _once => _ref.read(analyticsOnceStoreProvider);
  AnalyticsService get _analytics => _ref.read(analyticsServiceProvider);

  Future<void> trySetupComplete(
    Identity identity, {
    required bool avatarLoaded,
  }) async {
    if (identity.displayName.trim().isEmpty || !avatarLoaded) return;
    if (!await _once.markFired('setup_complete')) return;
    await _analytics.record('setup_complete');
  }

  Future<void> tryFirstShare() async {
    if (!await _once.markFired('first_share')) return;
    await _analytics.record('first_share');
  }

  Future<void> tryPaywallShown({required String surface}) async {
    if (!await _once.hasFired('first_share')) return;
    await _analytics.record('paywall_shown', properties: {'surface': surface});
  }

  Future<void> tryPurchase(String productId) async {
    final kind = _skuKind(productId);
    await _analytics.record('purchase', properties: {'sku_kind': kind});
  }

  Future<void> trySecondEncounter() async {
    if (!await _once.markFired('second_encounter')) return;
    await _analytics.record('second_encounter');
  }

  Future<void> tryInviteSent() async {
    if (!await _once.markFired('invite_sent')) return;
    await _analytics.record('invite_sent');
  }

  Future<void> tryExportShared() async {
    if (!await _once.markFired('export_shared')) return;
    await _analytics.record('export_shared');
  }

  Future<void> afterEncounterSave() async {
    final count = await _ref
        .read(encounterProcessorProvider)
        .uniqueEncounterCount();
    if (count >= 2) {
      await trySecondEncounter();
    }
  }

  static String _skuKind(String productId) {
    if (productId.contains('plus')) return 'plus';
    if (productId.contains('pack')) return 'pack';
    return 'cosmetic';
  }
}

final analyticsFunnelProvider = Provider<AnalyticsFunnel>((ref) {
  return AnalyticsFunnel(ref);
});