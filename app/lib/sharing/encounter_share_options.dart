import 'dart:convert';
import 'dart:io';

/// User-controlled fields included in QR/NFC encounter links.
///
/// See [docs/protocols/encounter-share-data.md] for the full wire contract.
class EncounterShareOptions {
  const EncounterShareOptions({
    this.includeEquippedCosmetics = true,
    this.includeCollectionProgress = false,
  });

  /// Catalog cosmetic ids, names, rarities, and series ids on the card.
  final bool includeEquippedCosmetics;

  /// Per-series owned/total counts (self-reported, not purchase proof).
  final bool includeCollectionProgress;

  static const defaults = EncounterShareOptions();

  EncounterShareOptions copyWith({
    bool? includeEquippedCosmetics,
    bool? includeCollectionProgress,
  }) {
    return EncounterShareOptions(
      includeEquippedCosmetics:
          includeEquippedCosmetics ?? this.includeEquippedCosmetics,
      includeCollectionProgress:
          includeCollectionProgress ?? this.includeCollectionProgress,
    );
  }

  Map<String, dynamic> toJson() => {
    'includeEquippedCosmetics': includeEquippedCosmetics,
    'includeCollectionProgress': includeCollectionProgress,
  };

  factory EncounterShareOptions.fromJson(Map<String, dynamic> json) {
    return EncounterShareOptions(
      includeEquippedCosmetics:
          json['includeEquippedCosmetics'] as bool? ?? true,
      includeCollectionProgress:
          json['includeCollectionProgress'] as bool? ?? false,
    );
  }
}

class EncounterSharePreferences {
  EncounterSharePreferences(this._file);

  final File _file;

  factory EncounterSharePreferences.inDirectory(Directory directory) {
    return EncounterSharePreferences(
      File('${directory.path}/encounter_share_options.json'),
    );
  }

  Future<EncounterShareOptions> read() async {
    if (!await _file.exists()) return EncounterShareOptions.defaults;
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return EncounterShareOptions.fromJson(decoded);
      }
    } catch (_) {}
    return EncounterShareOptions.defaults;
  }

  Future<void> write(EncounterShareOptions options) async {
    await _file.writeAsString(jsonEncode(options.toJson()));
  }
}
