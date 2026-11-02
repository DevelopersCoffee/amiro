import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'encounter_share_options.dart';

final encounterSharePreferencesProvider =
    Provider<EncounterSharePreferences>((ref) {
  throw UnimplementedError(
    'encounterSharePreferencesProvider must be overridden',
  );
});

final encounterShareOptionsProvider =
    AsyncNotifierProvider<EncounterShareOptionsNotifier, EncounterShareOptions>(
      EncounterShareOptionsNotifier.new,
    );

class EncounterShareOptionsNotifier extends AsyncNotifier<EncounterShareOptions> {
  @override
  Future<EncounterShareOptions> build() {
    return ref.read(encounterSharePreferencesProvider).read();
  }

  Future<void> saveOptions(EncounterShareOptions options) async {
    await ref.read(encounterSharePreferencesProvider).write(options);
    state = AsyncData(options);
  }
}
