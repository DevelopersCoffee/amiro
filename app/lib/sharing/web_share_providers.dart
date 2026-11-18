import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../identity/identity_providers.dart';
import '../identity/supabase_profile_cloud.dart';
import 'supabase_web_share_client.dart';
import 'web_share_preferences.dart';

final webSharePreferencesProvider = Provider<WebSharePreferences>((ref) {
  throw UnimplementedError('webSharePreferencesProvider must be overridden');
});

final webShareStateProvider =
    AsyncNotifierProvider<WebShareStateNotifier, WebShareState>(
      WebShareStateNotifier.new,
    );

class WebShareStateNotifier extends AsyncNotifier<WebShareState> {
  @override
  Future<WebShareState> build() {
    return ref.read(webSharePreferencesProvider).read();
  }

  Future<void> save(WebShareState state) async {
    await ref.read(webSharePreferencesProvider).write(state);
    this.state = AsyncData(state);
  }
}

final webShareClientProvider = Provider<WebShareService?>((ref) {
  final cloud = ref.watch(profileCloudProvider);
  if (cloud is! SupabaseProfileCloud) return null;
  return SupabaseWebShareClient(cloud);
});