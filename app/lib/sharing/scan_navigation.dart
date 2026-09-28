import 'package:flutter/widgets.dart';

import '../discovery/encounter_screen.dart';
import 'scan_result.dart';
import 'shared_profile_screen.dart';

/// The screen a resolved scan should open, or null when it isn't a usable
/// Amiro card. Shared by the QR scanner, NFC receive and deep links so they
/// can't drift apart.
Widget? screenForScan(ScanResult result) {
  return switch (result) {
    EncounterLink(:final encounter) => EncounterScreen(encounter: encounter),
    LegacyProfileLink(:final profile) => SharedProfileScreen(profile: profile),
    InvalidAmiroLink() || NotAmiroLink() => null,
  };
}
