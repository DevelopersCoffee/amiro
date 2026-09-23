# NFC/QR Sharing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Amiro's share loop — generate a QR code and (Android) an
NFC-emulated tap target from the current identity, scan/read one on the
receiving device, and render what was received on a new Shared Profile
screen. Works fully offline, no backend.

**Architecture:** `packages/sharing` is a pure-Dart orchestrator (no
platform imports) that builds/parses a self-contained, privacy-filtered
JSON payload carried as a custom-scheme URI (`amiro://share?d=<base64>`).
`packages/qr` wraps `qr_flutter`/`mobile_scanner`. `packages/nfc` wraps
`nfc_manager` for read (both platforms) and a custom Android
`HostApduService` for emulate (Android only — iOS cannot emulate for this
use case, see the spec). `app/` composes these into a Share screen, a QR
scan screen, an NFC listener, and a new Shared Profile view screen.

**Tech Stack:** `qr_flutter` ^4.1.0, `mobile_scanner` ^7.4.2, `nfc_manager`
^4.2.1, `app_links` ^7.2.1, a custom Kotlin `HostApduService` for Android
HCE, Riverpod (existing pattern), Isar (existing — no schema changes
needed, this pass is not persisted).

**Spec:** [docs/superpowers/specs/2026-09-23-nfc-sharing-design.md](../specs/2026-09-23-nfc-sharing-design.md)

## Global Constraints

- NFC emulate (Android `HostApduService`) is Android-only. iOS gets NFC
  *read* only, no emulate UI at all — this is intentional per Apple policy,
  not a gap to fill.
- Payload is self-contained (embeds public profile fields + avatar
  definition), not a bare ID — no backend dependency this pass.
- Only fields with `PrivacyFlag.isPublic == true` (via `Identity.publicFields()`)
  go into the payload; `avatarDefinitionJson` is always included when present.
- URI scheme: `amiro://share?d=<base64url(json)>`, payload `v: 1`.
- `packages/sharing` has no direct platform imports (matches
  `avatar_renderer`'s isolation pattern for `thermion_flutter`).
- Real camera QR scanning and real NFC emulate/read are not unit-testable —
  flagged for a device spike; wrapper logic is tested via fakes.

---

## File Structure

```
packages/sharing/
  pubspec.yaml
  lib/
    sharing.dart
    src/
      shared_profile.dart       # SharedProfile model
      share_payload_codec.dart  # buildShareUri / parseShareUri
  test/
    share_payload_codec_test.dart

packages/qr/
  pubspec.yaml
  lib/
    qr.dart
    src/
      qr_generator.dart   # buildQrWidget wrapping qr_flutter
      qr_scanner.dart      # QrScanner interface + MobileQrScanner impl
  test/
    qr_generator_test.dart

packages/nfc/
  pubspec.yaml
  lib/
    nfc.dart
    src/
      nfc_reader.dart      # NfcReader interface + ManagerNfcReader impl (nfc_manager)
      nfc_emulator.dart     # NfcEmulator interface + AndroidNfcEmulator impl (platform channel) + NoopNfcEmulator (iOS)
  android/                  # HostApduService native module
    ...
  test/
    nfc_emulator_test.dart

app/
  lib/
    sharing/
      sharing_providers.dart
      share_screen.dart
      qr_scan_screen.dart
      shared_profile_screen.dart
  test/
    sharing/
      share_screen_test.dart
      shared_profile_screen_test.dart
```

---

## Task 1: `packages/sharing` — `SharedProfile` model + payload codec

**Files:**
- Create: `packages/sharing/pubspec.yaml`
- Create: `packages/sharing/analysis_options.yaml`
- Create: `packages/sharing/lib/sharing.dart`
- Create: `packages/sharing/lib/src/shared_profile.dart`
- Create: `packages/sharing/lib/src/share_payload_codec.dart`
- Test: `packages/sharing/test/share_payload_codec_test.dart`

**Interfaces:**
- Consumes: `Identity`, `PrivacyFlag` from `identity_core`.
- Produces: `class SharedProfile { final String id, displayName, username; final String? bio, avatarDefinitionJson, email, mobile, xHandle, instagramHandle, website; }`, `String buildShareUri(Identity identity)`, `SharedProfile? parseShareUri(String uri)`.

- [ ] **Step 1: Create `packages/sharing/pubspec.yaml`**

```yaml
name: sharing
description: Amiro identity sharing orchestration (payload build/parse, no platform imports).
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  identity_core:
    path: ../identity_core

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

Also create `packages/sharing/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Write the failing test — `packages/sharing/test/share_payload_codec_test.dart`**

```dart
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

void main() {
  group('buildShareUri', () {
    test('includes only fields flagged public', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'bio': PrivacyFlag(true),
          'email': PrivacyFlag(false),
        },
      );

      final uri = buildShareUri(identity);
      final parsed = parseShareUri(uri)!;

      expect(parsed.id, 'id-1');
      expect(parsed.displayName, 'Uday');
      expect(parsed.username, 'uday');
      expect(parsed.bio, 'Software Engineer');
      expect(parsed.email, isNull);
    });

    test('always includes avatarDefinitionJson when present, regardless of privacy flags', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        avatarDefinitionJson: '{"id":"default","body":"body_superhero_male"}',
      );

      final uri = buildShareUri(identity);
      final parsed = parseShareUri(uri)!;

      expect(parsed.avatarDefinitionJson, '{"id":"default","body":"body_superhero_male"}');
    });

    test('produces a URI with the amiro://share scheme', () {
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      final uri = buildShareUri(identity);

      expect(uri, startsWith('amiro://share?d='));
    });
  });

  group('parseShareUri', () {
    test('round-trips displayName, username, bio and avatarDefinitionJson', () {
      final identity = Identity(
        id: 'id-2',
        displayName: 'Ada',
        username: 'ada',
        bio: 'Engineer',
        avatarDefinitionJson: '{"id":"x"}',
        privacy: const {'bio': PrivacyFlag(true)},
      );

      final parsed = parseShareUri(buildShareUri(identity))!;

      expect(parsed.id, 'id-2');
      expect(parsed.displayName, 'Ada');
      expect(parsed.username, 'ada');
      expect(parsed.bio, 'Engineer');
      expect(parsed.avatarDefinitionJson, '{"id":"x"}');
    });

    test('returns null for a non-amiro URI', () {
      expect(parseShareUri('https://example.com/foo'), isNull);
    });

    test('returns null for a malformed amiro URI (bad base64)', () {
      expect(parseShareUri('amiro://share?d=not-valid-base64!!!'), isNull);
    });

    test('returns null when the d query parameter is missing', () {
      expect(parseShareUri('amiro://share'), isNull);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/sharing && dart pub get && dart test`
Expected: FAIL — `sharing` library doesn't exist yet.

- [ ] **Step 4: Implement `packages/sharing/lib/src/shared_profile.dart`**

```dart
/// A received, self-contained share payload — everything needed to render
/// someone else's profile without a network call. See
/// docs/superpowers/specs/2026-09-23-nfc-sharing-design.md §4.
class SharedProfile {
  final String id;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarDefinitionJson;
  final String? email;
  final String? mobile;
  final String? xHandle;
  final String? instagramHandle;
  final String? website;

  const SharedProfile({
    required this.id,
    required this.displayName,
    required this.username,
    this.bio,
    this.avatarDefinitionJson,
    this.email,
    this.mobile,
    this.xHandle,
    this.instagramHandle,
    this.website,
  });
}
```

- [ ] **Step 5: Implement `packages/sharing/lib/src/share_payload_codec.dart`**

```dart
import 'dart:convert';

import 'package:identity_core/identity_core.dart';

import 'shared_profile.dart';

const _kScheme = 'amiro';
const _kHost = 'share';
const _kPayloadVersion = 1;

/// Builds the share URI for [identity]: only fields flagged public via
/// [Identity.publicFields] are included. `avatarDefinitionJson` is always
/// included when present — the avatar itself isn't privacy-sensitive the
/// way contact fields are.
String buildShareUri(Identity identity) {
  final public = identity.publicFields();
  final payload = <String, dynamic>{
    'v': _kPayloadVersion,
    'id': identity.id,
    'displayName': identity.displayName,
    'username': identity.username,
    if (public.containsKey('bio')) 'bio': public['bio'],
    if (public.containsKey('email')) 'email': public['email'],
    if (public.containsKey('mobile')) 'mobile': public['mobile'],
    if (public.containsKey('xHandle')) 'xHandle': public['xHandle'],
    if (public.containsKey('instagramHandle'))
      'instagramHandle': public['instagramHandle'],
    if (public.containsKey('website')) 'website': public['website'],
    if (identity.avatarDefinitionJson != null)
      'avatarDefinitionJson': identity.avatarDefinitionJson,
  };

  final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$_kScheme://$_kHost?d=$encoded';
}

/// Parses a share URI back into a [SharedProfile]. Returns `null` for any
/// URI that isn't a well-formed `amiro://share` link — callers should
/// treat `null` as "not one of ours", not throw.
SharedProfile? parseShareUri(String uri) {
  final Uri parsed;
  try {
    parsed = Uri.parse(uri);
  } on FormatException {
    return null;
  }

  if (parsed.scheme != _kScheme || parsed.host != _kHost) return null;

  final encoded = parsed.queryParameters['d'];
  if (encoded == null) return null;

  final Map<String, dynamic> json;
  try {
    final decodedBytes = base64Url.decode(encoded);
    json = jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;
  } on FormatException {
    return null;
  } on FormatException catch (_) {
    return null;
  } catch (_) {
    return null;
  }

  final id = json['id'] as String?;
  final displayName = json['displayName'] as String?;
  final username = json['username'] as String?;
  if (id == null || displayName == null || username == null) return null;

  return SharedProfile(
    id: id,
    displayName: displayName,
    username: username,
    bio: json['bio'] as String?,
    avatarDefinitionJson: json['avatarDefinitionJson'] as String?,
    email: json['email'] as String?,
    mobile: json['mobile'] as String?,
    xHandle: json['xHandle'] as String?,
    instagramHandle: json['instagramHandle'] as String?,
    website: json['website'] as String?,
  );
}
```

- [ ] **Step 6: Create `packages/sharing/lib/sharing.dart`**

```dart
export 'src/shared_profile.dart';
export 'src/share_payload_codec.dart';
```

- [ ] **Step 7: Run tests to verify pass**

Run: `cd packages/sharing && dart test`
Expected: PASS (7 tests).

- [ ] **Step 8: Commit**

```bash
git add packages/sharing
git commit -m "feat(sharing): add SharedProfile model and share URI codec"
```

---

## Task 2: `packages/qr` — QR generation + scanning

**Files:**
- Create: `packages/qr/pubspec.yaml`
- Create: `packages/qr/analysis_options.yaml`
- Create: `packages/qr/lib/qr.dart`
- Create: `packages/qr/lib/src/qr_generator.dart`
- Create: `packages/qr/lib/src/qr_scanner.dart`
- Test: `packages/qr/test/qr_generator_test.dart`

**Interfaces:**
- Produces: `Widget buildQrWidget(String data, {double size = 240})`, `abstract class QrScanner { Future<String?> scanOnce(); }`, `class MobileQrScanner implements QrScanner`.

- [ ] **Step 1: Create `packages/qr/pubspec.yaml`**

```yaml
name: qr
description: QR generation and scanning for Amiro identity sharing.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0
```

Also create `packages/qr/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Write the failing test — `packages/qr/test/qr_generator_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

void main() {
  testWidgets('buildQrWidget renders a QrImageView for the given data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc'))),
    );

    expect(find.byType(buildQrWidget('amiro://share?d=abc').runtimeType), findsWidgets);
  });

  testWidgets('buildQrWidget respects the size parameter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildQrWidget('amiro://share?d=abc', size: 100))),
    );
    await tester.pumpAndSettle();

    final sizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'QrImageView'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(sizedBox.width, 100);
    expect(sizedBox.height, 100);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/qr && flutter pub get && flutter test test/qr_generator_test.dart`
Expected: FAIL — `qr` library/`buildQrWidget` doesn't exist.

- [ ] **Step 4: Implement `packages/qr/lib/src/qr_generator.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders [data] as a scannable QR code. Used for the identity share URI —
/// [data] is expected to already be the full `amiro://share?d=...` URI, not
/// raw profile data.
Widget buildQrWidget(String data, {double size = 240}) {
  return SizedBox(
    width: size,
    height: size,
    child: QrImageView(
      data: data,
      version: QrVersions.auto,
      backgroundColor: const Color(0xFFFFFFFF),
    ),
  );
}
```

- [ ] **Step 5: Run the generator test to verify pass**

Run: `cd packages/qr && flutter test test/qr_generator_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Implement `packages/qr/lib/src/qr_scanner.dart`** (no test — thin wrapper over a real camera, exercised in Task 6's widget test via a fake, not here)

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans a single QR code and returns its raw string content, or `null` if
/// the scan was cancelled. Kept as an interface so screens can be tested
/// against a fake instead of the real camera.
abstract class QrScanner {
  Future<String?> scanOnce();
}

/// Real [QrScanner] backed by `mobile_scanner`'s camera view. This class
/// itself isn't directly unit-testable (needs a real camera) — the
/// `MobileScannerController` it wraps is exercised through the
/// `MobileScanner` widget in `qr_scan_screen.dart` (Task 6), which is where
/// manual/device verification happens.
class MobileQrScanner implements QrScanner {
  final MobileScannerController controller;

  MobileQrScanner({MobileScannerController? controller})
      : controller = controller ?? MobileScannerController();

  @override
  Future<String?> scanOnce() {
    final completer = Completer<String?>();
    late final StreamSubscription sub;
    sub = controller.barcodes.listen((capture) {
      final value = capture.barcodes.firstOrNull?.rawValue;
      if (value != null) {
        sub.cancel();
        completer.complete(value);
      }
    });
    return completer.future;
  }
}
```

Add the missing imports at the top of that file:

```dart
import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';
```

(Combine with the class above — one file, imports at top.)

- [ ] **Step 7: Create `packages/qr/lib/qr.dart`**

```dart
export 'src/qr_generator.dart';
export 'src/qr_scanner.dart';
```

- [ ] **Step 8: Run analyze and the generator test**

Run: `cd packages/qr && flutter analyze && flutter test test/qr_generator_test.dart`
Expected: both clean/passing.

- [ ] **Step 9: Commit**

```bash
git add packages/qr
git commit -m "feat(qr): add QR generation and scanner wrapper"
```

---

## Task 3: `packages/nfc` — read (both platforms) + emulate interface

**Files:**
- Create: `packages/nfc/pubspec.yaml`
- Create: `packages/nfc/analysis_options.yaml`
- Create: `packages/nfc/lib/nfc.dart`
- Create: `packages/nfc/lib/src/nfc_reader.dart`
- Create: `packages/nfc/lib/src/nfc_emulator.dart`
- Test: `packages/nfc/test/nfc_emulator_test.dart`

**Interfaces:**
- Produces: `abstract class NfcReader { Stream<String> readIncomingPayload(); Future<void> stop(); }`, `class ManagerNfcReader implements NfcReader`, `abstract class NfcEmulator { bool get canEmulate; Future<void> writeIdentityPayload(String uri); Future<void> stopEmulating(); }`, `class AndroidNfcEmulator implements NfcEmulator` (platform channel, Task 4 provides the native side), `class NoopNfcEmulator implements NfcEmulator` (`canEmulate => false`, used on iOS).

- [ ] **Step 1: Create `packages/nfc/pubspec.yaml`**

```yaml
name: nfc
description: NFC read (both platforms) and emulate (Android only) for Amiro identity sharing.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  nfc_manager: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0
```

Also create `packages/nfc/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Implement `packages/nfc/lib/src/nfc_reader.dart`** (no unit test — needs real NFC hardware; interface exists so callers can be tested against a fake)

```dart
import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Listens for an incoming NDEF tag read (either a physical tag or an
/// Android device emulating one via HCE) and emits its text payload.
/// Not directly unit-testable — needs real NFC hardware. See the device
/// spike note in the design spec §8.
abstract class NfcReader {
  Stream<String> readIncomingPayload();
  Future<void> stop();
}

class ManagerNfcReader implements NfcReader {
  final _controller = StreamController<String>.broadcast();
  bool _sessionActive = false;

  @override
  Stream<String> readIncomingPayload() {
    if (!_sessionActive) {
      _sessionActive = true;
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          final message = ndef?.cachedMessage;
          final record = message?.records.firstOrNull;
          if (record != null) {
            final text = _decodeTextRecord(record);
            if (text != null) _controller.add(text);
          }
        },
      );
    }
    return _controller.stream;
  }

  @override
  Future<void> stop() async {
    if (_sessionActive) {
      _sessionActive = false;
      await NfcManager.instance.stopSession();
    }
  }

  String? _decodeTextRecord(NdefRecord record) {
    // NDEF well-known text records store a status byte + IANA language
    // code before the actual text — strip that prefix rather than assume
    // offset 0, since the language code length is encoded in the status
    // byte's low bits (typically 2 for "en", but not guaranteed).
    if (record.payload.isEmpty) return null;
    final statusByte = record.payload[0];
    final languageCodeLength = statusByte & 0x3F;
    final textStart = 1 + languageCodeLength;
    if (textStart > record.payload.length) return null;
    return String.fromCharCodes(record.payload.sublist(textStart));
  }
}
```

- [ ] **Step 3: Write the failing test for the emulator interface — `packages/nfc/test/nfc_emulator_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc/nfc.dart';

void main() {
  test('NoopNfcEmulator reports canEmulate false and no-ops writes', () async {
    final emulator = NoopNfcEmulator();

    expect(emulator.canEmulate, isFalse);

    // Should complete without throwing — callers on iOS call this
    // unconditionally guarded by `canEmulate`, but the no-op itself must
    // still be safe to call.
    await emulator.writeIdentityPayload('amiro://share?d=abc');
    await emulator.stopEmulating();
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd packages/nfc && flutter pub get && flutter test test/nfc_emulator_test.dart`
Expected: FAIL — `NoopNfcEmulator` doesn't exist.

- [ ] **Step 5: Implement `packages/nfc/lib/src/nfc_emulator.dart`**

```dart
import 'package:flutter/services.dart';

/// Makes this device emulate an NFC tag carrying [uri] so another device
/// can tap-and-read it. Android-only — see the design spec §2 for why iOS
/// cannot do this for a general-purpose sharing use case.
abstract class NfcEmulator {
  bool get canEmulate;
  Future<void> writeIdentityPayload(String uri);
  Future<void> stopEmulating();
}

const _kChannelName = 'amiro/nfc_hce';

/// Real emulator, backed by a custom Android `HostApduService` (see
/// `packages/nfc/android/` and Task 4). Talking to the native side isn't
/// unit-testable without a device — the platform channel call itself is
/// exercised in the Task 4 device spike, not here.
class AndroidNfcEmulator implements NfcEmulator {
  static const _channel = MethodChannel(_kChannelName);

  @override
  bool get canEmulate => true;

  @override
  Future<void> writeIdentityPayload(String uri) async {
    await _channel.invokeMethod('writeIdentityPayload', {'uri': uri});
  }

  @override
  Future<void> stopEmulating() async {
    await _channel.invokeMethod('stopEmulating');
  }
}

/// No-op emulator for platforms that can't emulate (iOS). Callers should
/// still gate emulate-only UI behind `canEmulate`, but this makes it safe
/// to call the methods unconditionally too.
class NoopNfcEmulator implements NfcEmulator {
  @override
  bool get canEmulate => false;

  @override
  Future<void> writeIdentityPayload(String uri) async {}

  @override
  Future<void> stopEmulating() async {}
}
```

- [ ] **Step 6: Run tests to verify pass**

Run: `cd packages/nfc && flutter test test/nfc_emulator_test.dart`
Expected: PASS (1 test).

- [ ] **Step 7: Create `packages/nfc/lib/nfc.dart`**

```dart
export 'src/nfc_reader.dart';
export 'src/nfc_emulator.dart';
```

- [ ] **Step 8: Run analyze**

Run: `cd packages/nfc && flutter analyze`
Expected: clean. If `nfc_manager_ndef` isn't a real separate package (check
`nfc_manager` 4.2.1's own exports first — NDEF support may be bundled
directly in `nfc_manager` rather than a companion package), adjust the
import in `nfc_reader.dart` to match whatever the installed version
actually exports. Don't guess — check `dart pub deps` output or the
package's own `lib/nfc_manager.dart` barrel file after `flutter pub get`.

- [ ] **Step 9: Commit**

```bash
git add packages/nfc
git commit -m "feat(nfc): add NDEF reader and emulator interface (Android HCE stub)"
```

---

## Task 4: Android `HostApduService` — native NFC emulate implementation

**Files:**
- Create: `app/android/app/src/main/kotlin/com/developerscoffee/amiro_app/AmiroHceService.kt`
- Create: `app/android/app/src/main/res/xml/apduservice.xml`
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Modify: `app/android/app/src/main/kotlin/com/developerscoffee/amiro_app/MainActivity.kt`

**Interfaces:**
- Consumes: nothing from earlier Dart tasks directly — this is the native
  counterpart the `AndroidNfcEmulator` platform channel (`amiro/nfc_hce`,
  Task 3) talks to.
- Produces: a running `HostApduService` that responds to NFC reader polls
  with whatever URI was last set via the `writeIdentityPayload` /
  `stopEmulating` method channel calls.

This task is native Android code with no Dart test harness — it cannot be
TDD'd the way earlier tasks were. Verify manually per Task 7's device spike.

- [ ] **Step 1: Create the AID routing config — `app/android/app/src/main/res/xml/apduservice.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<host-apdu-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/amiro_hce_description"
    android:requireDeviceUnlock="false">
    <aid-group android:description="@string/amiro_hce_description"
        android:category="other">
        <aid-filter android:name="F0414D49524F303031" />
    </aid-group>
</host-apdu-service>
```

(The AID `F0414D49524F303031` is `\xF0` + ASCII "AMIRO001" — a
custom/unregistered AID prefixed with `F0`, which is reserved for
proprietary/non-payment use per ISO 7816, appropriate for a
non-payment app-to-app share.)

Add the referenced string — create/edit `app/android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="amiro_hce_description">Amiro identity share</string>
</resources>
```

- [ ] **Step 2: Implement the HCE service — `app/android/app/src/main/kotlin/com/developerscoffee/amiro_app/AmiroHceService.kt`**

```kotlin
package com.developerscoffee.amiro_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Emulates an NFC tag carrying the current share URI, so another device
 * (Android, or an iPhone using Core NFC to read) can tap and read it.
 *
 * The URI is set/cleared via [AmiroHceService.currentPayload], written by
 * [MainActivity]'s method channel handler (see writeIdentityPayload /
 * stopEmulating). This service has no direct Flutter engine access — it's
 * a plain Android component the OS starts on tag-reader polling, so state
 * is passed through this static field rather than a channel call from
 * inside the service itself.
 */
class AmiroHceService : HostApduService() {

    companion object {
        /** The URI currently being shared, or null if not emulating. */
        @Volatile
        var currentPayload: String? = null

        private val SELECT_AID_APDU = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x08,
            0xF0.toByte(), 0x41, 0x4D, 0x49, 0x52, 0x4F, 0x30, 0x30, 0x31
        )
        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val STATUS_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val payload = currentPayload
        if (payload == null) {
            return STATUS_NOT_FOUND
        }
        // Minimal protocol: any SELECT AID command (or any command at all,
        // since this service only registers for our one AID) gets the full
        // UTF-8 payload bytes back, followed by the success status word.
        // A real NDEF Type 4 Tag implementation would parse SELECT/READ
        // BINARY commands properly — this simplified version works because
        // both sides are our own app (Android emulate <-> our own NFC
        // reader), and iOS's Core NFC reader (Task 7's cross-device case)
        // reads this as raw APDU response bytes too. Verify this
        // simplification holds during the Task 7 device spike; if iOS's
        // Core NFC requires a spec-correct NDEF Type 4 Tag exchange, this
        // will need real READ BINARY / SELECT NDEF file handling.
        val payloadBytes = payload.toByteArray(Charsets.UTF_8)
        return payloadBytes + STATUS_SUCCESS
    }

    override fun onDeactivated(reason: Int) {
        // No cleanup needed — currentPayload persists until explicitly
        // cleared via stopEmulating(), so re-tapping without re-triggering
        // Share still works.
    }
}
```

- [ ] **Step 3: Register the service in the manifest — modify `app/android/app/src/main/AndroidManifest.xml`**

Add inside the `<application>` tag (alongside the existing `<activity>`):

```xml
        <service
            android:name=".AmiroHceService"
            android:exported="true"
            android:permission="android.permission.BIND_NFC_SERVICE">
            <intent-filter>
                <action android:name="android.nfc.cardemulation.action.HOST_APDU_SERVICE" />
            </intent-filter>
            <meta-data
                android:name="android.nfc.cardemulation.host_apdu_service"
                android:resource="@xml/apduservice" />
        </service>
```

Add the NFC permission near the top of the manifest (as a sibling of any
existing `<uses-permission>`, or as the first child of `<manifest>` if
none exist yet):

```xml
    <uses-permission android:name="android.permission.NFC" />
    <uses-feature android:name="android.hardware.nfc" android:required="false" />
```

(`required="false"` — the app must still install and run on
non-NFC-capable Android devices; NFC emulate/read UI is conditionally
shown based on runtime capability, not a hard install-time requirement.)

- [ ] **Step 4: Wire the method channel in `MainActivity.kt`**

Read the current contents first:

```bash
cat app/android/app/src/main/kotlin/com/developerscoffee/amiro_app/MainActivity.kt
```

It's almost certainly the default Flutter template (an empty
`FlutterActivity` subclass). Replace its contents with:

```kotlin
package com.developerscoffee.amiro_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "amiro/nfc_hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "writeIdentityPayload" -> {
                        val uri = call.argument<String>("uri")
                        AmiroHceService.currentPayload = uri
                        result.success(null)
                    }
                    "stopEmulating" -> {
                        AmiroHceService.currentPayload = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

- [ ] **Step 5: Verify the app still builds**

Run: `cd app && flutter build apk --debug 2>&1 | tail -30`
Expected: builds successfully. This confirms the Kotlin compiles and the
manifest/XML are well-formed — it does NOT verify the HCE service actually
works (needs Task 7's device spike).

- [ ] **Step 6: Commit**

```bash
git add app/android
git commit -m "feat(android): add HostApduService for NFC identity emulate"
```

---

## Task 5: `app_links` wiring — `amiro://` scheme registration (both platforms)

**Files:**
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Modify: `app/ios/Runner/Info.plist`
- Modify: `app/pubspec.yaml`
- Create: `app/lib/sharing/sharing_providers.dart`

**Interfaces:**
- Consumes: `parseShareUri` from `packages/sharing` (Task 1).
- Produces: `final incomingShareLinkProvider = StreamProvider<SharedProfile?>((ref) { ... })` — a Riverpod stream other screens (Task 8) listen to for incoming `amiro://` links, whether the app was launched cold via the link or already running.

- [ ] **Step 1: Add `app_links` to `app/pubspec.yaml`**

Add under `dependencies:` (alongside `avatar_renderer`, etc.):

```yaml
  app_links: ^7.2.1
  sharing:
    path: ../packages/sharing
  qr:
    path: ../packages/qr
  nfc:
    path: ../packages/nfc
```

- [ ] **Step 2: Register the custom scheme on Android — modify `app/android/app/src/main/AndroidManifest.xml`**

Add a new `<intent-filter>` block to the existing `<activity>` tag (the one
already there for `MainActivity`, alongside its existing launcher
intent-filter — don't replace the existing one, add this as a second
`<intent-filter>` inside the same `<activity>`):

```xml
            <intent-filter android:autoVerify="false">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="amiro" android:host="share" />
            </intent-filter>
```

- [ ] **Step 3: Register the custom scheme on iOS — modify `app/ios/Runner/Info.plist`**

Add a new top-level key (as a sibling of existing keys like `CFBundleName`,
inside the outer `<dict>`):

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>app.amiro.share</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>amiro</string>
			</array>
		</dict>
	</array>
```

- [ ] **Step 4: Implement `app/lib/sharing/sharing_providers.dart`**

```dart
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sharing/sharing.dart';

/// Emits a [SharedProfile] whenever the app is opened via an `amiro://`
/// link — whether cold-launched from it or already running and receiving
/// it via the platform's runtime link delivery. Emits `null` if a link
/// arrives that isn't a valid Amiro share link (so listeners can
/// distinguish "no link yet" from "got something, but it wasn't ours" if
/// needed — though `parseShareUri` returning `null` is the more common
/// path here).
final incomingShareLinkProvider = StreamProvider<SharedProfile?>((ref) {
  final appLinks = AppLinks();
  return appLinks.uriLinkStream.map((uri) => parseShareUri(uri.toString()));
});
```

- [ ] **Step 5: Verify the app still builds and analyzes**

Run: `cd app && flutter pub get && flutter analyze`
Expected: clean (this task adds a provider with no UI yet, so no widget
test — it's exercised end-to-end in Task 8's Shared Profile screen work).

- [ ] **Step 6: Commit**

```bash
git add app/android/app/src/main/AndroidManifest.xml app/ios/Runner/Info.plist app/pubspec.yaml app/lib/sharing/sharing_providers.dart
git commit -m "feat(app): register amiro:// scheme and wire incoming-link provider"
```

---

## Task 6: Share screen — QR display + Android-only NFC section

**Files:**
- Create: `app/lib/sharing/share_screen.dart`
- Test: `app/test/sharing/share_screen_test.dart`
- Modify: `app/lib/app.dart` (add a third tab)

**Interfaces:**
- Consumes: `currentIdentityProvider` (from `identity_providers.dart`),
  `buildShareUri` (from `sharing`), `buildQrWidget` (from `qr`),
  `NfcEmulator`/`canEmulate` (from `nfc`).
- Produces: `class ShareScreen extends ConsumerWidget`, and a new
  `nfcEmulatorProvider` (`Provider<NfcEmulator>`, overridden in `main.dart`
  with `AndroidNfcEmulator()` or `NoopNfcEmulator()` based on
  `Platform.isAndroid`).

- [ ] **Step 1: Write the failing test — `app/test/sharing/share_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/sharing/share_screen.dart';
import 'package:amiro_app/sharing/sharing_providers.dart' show nfcEmulatorProvider;

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? stored;
  _InMemoryIdentityRepository(this.stored);

  @override
  Future<Identity?> getCurrent() async => stored;
  @override
  Future<void> save(Identity identity) async => stored = identity;
  @override
  Future<void> clear() async => stored = null;
}

Widget _screen(NfcEmulator emulator, Identity identity) {
  return ProviderScope(
    overrides: [
      identityRepositoryProvider.overrideWithValue(_InMemoryIdentityRepository(identity)),
      nfcEmulatorProvider.overrideWithValue(emulator),
    ],
    child: const MaterialApp(home: ShareScreen()),
  );
}

void main() {
  testWidgets('shows a QR code for the current identity', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(NoopNfcEmulator(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shareQrCode')), findsOneWidget);
  });

  testWidgets('shows NFC section when the emulator can emulate', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(_FakeCanEmulate(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfcShareSection')), findsOneWidget);
  });

  testWidgets('hides NFC section when the emulator cannot emulate', (tester) async {
    final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
    await tester.pumpWidget(_screen(NoopNfcEmulator(), identity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfcShareSection')), findsNothing);
  });
}

class _FakeCanEmulate implements NfcEmulator {
  @override
  bool get canEmulate => true;
  @override
  Future<void> writeIdentityPayload(String uri) async {}
  @override
  Future<void> stopEmulating() async {}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/sharing/share_screen_test.dart`
Expected: FAIL — `ShareScreen`, `nfcEmulatorProvider` don't exist.

- [ ] **Step 3: Add `nfcEmulatorProvider` to `app/lib/sharing/sharing_providers.dart`**

Append to the file created in Task 5:

```dart
import 'package:nfc/nfc.dart';

/// Overridden in `main.dart` with `AndroidNfcEmulator()` or
/// `NoopNfcEmulator()` based on the real platform; overridden in tests
/// with a fake.
final nfcEmulatorProvider = Provider<NfcEmulator>((ref) {
  throw UnimplementedError('nfcEmulatorProvider must be overridden');
});
```

(Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` if not
already imported in that file from Task 5.)

- [ ] **Step 4: Implement `app/lib/sharing/share_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qr/qr.dart';
import 'package:sharing/sharing.dart';

import '../identity/identity_providers.dart';
import 'sharing_providers.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _emulating = false;

  Future<void> _toggleNfcEmulate(String shareUri) async {
    final emulator = ref.read(nfcEmulatorProvider);
    if (_emulating) {
      await emulator.stopEmulating();
    } else {
      await emulator.writeIdentityPayload(shareUri);
    }
    setState(() => _emulating = !_emulating);
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    final emulator = ref.watch(nfcEmulatorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: identityAsync.when(
        data: (identity) {
          if (identity == null) {
            return const Center(child: Text('Create your identity first'));
          }
          final shareUri = buildShareUri(identity);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                key: const Key('shareQrCode'),
                child: buildQrWidget(shareUri),
              ),
              if (emulator.canEmulate) ...[
                const SizedBox(height: 32),
                Column(
                  key: const Key('nfcShareSection'),
                  children: [
                    const Text('Or tap another phone to share'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _toggleNfcEmulate(shareUri),
                      child: Text(_emulating ? 'Stop NFC sharing' : 'Start NFC sharing'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify pass**

Run: `cd app && flutter test test/sharing/share_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Add a Share tab to `app/lib/app.dart`**

Read the current file first:

```bash
cat app/lib/app.dart
```

It has a `_RootTabs` widget with a `screens` list (`IdentityEditScreen`,
`AvatarScreen`) and matching `NavigationDestination`s. Add `ShareScreen` as
a third entry — update the imports, the `screens` const list, and the
`destinations` list to include:

```dart
import 'sharing/share_screen.dart';
```

```dart
const screens = [IdentityEditScreen(), AvatarScreen(), ShareScreen()];
```

```dart
        NavigationDestination(icon: Icon(Icons.ios_share), label: 'Share'),
```

(Match the exact existing style/structure of the two current entries —
read the file first and make the minimal corresponding addition, don't
restructure what's already there.)

- [ ] **Step 7: Run the full app test suite**

Run: `cd app && flutter analyze && flutter test`
Expected: all clean/passing (existing tests plus the 3 new ones).

- [ ] **Step 8: Commit**

```bash
git add app/lib/sharing/share_screen.dart app/lib/sharing/sharing_providers.dart app/lib/app.dart app/test/sharing/share_screen_test.dart
git commit -m "feat(app): add Share screen with QR and Android-only NFC section"
```

---

## Task 7: QR scan screen + wiring the real `AndroidNfcEmulator`/reader in `main.dart`

**Files:**
- Create: `app/lib/sharing/qr_scan_screen.dart`
- Modify: `app/lib/main.dart`

**Interfaces:**
- Consumes: `QrScanner`/`MobileQrScanner` (from `qr`), `parseShareUri`
  (from `sharing`).
- Produces: `class QrScanScreen extends StatefulWidget` — navigates to
  `SharedProfileScreen` (Task 8) on a successful scan.

- [ ] **Step 1: Implement `app/lib/sharing/qr_scan_screen.dart`**

No widget test here — `MobileScanner`'s actual camera view isn't
meaningfully testable in a widget test environment (no real camera). This
screen is covered by the Task 9 device spike instead.

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sharing/sharing.dart';

import 'shared_profile_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final profile = parseShareUri(raw);
    if (profile == null) return;

    _handled = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SharedProfileScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Amiro QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
```

- [ ] **Step 2: Wire the real NFC emulator and reader in `app/lib/main.dart`**

Read the current file first:

```bash
cat app/lib/main.dart
```

Add the platform-conditional emulator, alongside the existing
`avatarRendererProvider`/`identityRepositoryProvider` overrides in the
`ProviderScope`'s `overrides` list:

```dart
import 'dart:io' show Platform;

import 'package:nfc/nfc.dart';

import 'sharing/sharing_providers.dart';
```

```dart
final nfcEmulator = Platform.isAndroid ? AndroidNfcEmulator() : NoopNfcEmulator();
```

Add `nfcEmulatorProvider.overrideWithValue(nfcEmulator),` to the
`overrides` list (same list that already has
`identityRepositoryProvider.overrideWithValue(...)` and
`avatarRendererProvider.overrideWithValue(...)`).

- [ ] **Step 3: Add a way to reach the scan screen from the Share screen**

Modify `app/lib/sharing/share_screen.dart` (from Task 6) — add an
`AppBar` action:

```dart
import 'qr_scan_screen.dart';
```

In the `Scaffold`'s `appBar:`, add:

```dart
        actions: [
          IconButton(
            key: const Key('openScannerButton'),
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            ),
          ),
        ],
```

- [ ] **Step 4: Run analyze**

Run: `cd app && flutter analyze`
Expected: clean. (`SharedProfileScreen` doesn't exist until Task 8 — if
analyze fails on that missing import, that's expected and will be
resolved by Task 8; don't stub it out here, implement Task 8 next.)

- [ ] **Step 5: Commit** (only after Task 8 exists — see note)

This task's commit is folded into Task 8's commit, since
`qr_scan_screen.dart` references `SharedProfileScreen`, which doesn't
exist until Task 8. Proceed directly to Task 8 before committing either.

---

## Task 8: Shared Profile screen

**Files:**
- Create: `app/lib/sharing/shared_profile_screen.dart`
- Test: `app/test/sharing/shared_profile_screen_test.dart`

**Interfaces:**
- Consumes: `SharedProfile` (from `sharing`), `AvatarRenderer`/
  `avatarRendererProvider` (from `avatar_renderer` / existing app
  providers), `AvatarDefinition.fromJson`.
- Produces: `class SharedProfileScreen extends ConsumerStatefulWidget`.

- [ ] **Step 1: Write the failing test — `app/test/sharing/shared_profile_screen_test.dart`**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/sharing/shared_profile_screen.dart';

class _FakeAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;

  @override
  AvatarDefinition? get current => _current;
  @override
  Future<void> load(AvatarDefinition definition) async => _current = definition;
  @override
  Widget buildView() => const ColoredBox(color: Colors.grey, child: SizedBox(height: 200));
  @override
  Future<void> updateSlot(String slot, String? assetId) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('renders the shared profile\'s name, username, bio and avatar', (tester) async {
    final profile = SharedProfile(
      id: 'id-1',
      displayName: 'Ada',
      username: 'ada',
      bio: 'Engineer',
      avatarDefinitionJson: jsonEncode(
        const AvatarDefinition(id: 'shared', body: 'body_superhero_male').toJson(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(_FakeAvatarRenderer())],
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
  });

  testWidgets('renders without a bio section when bio is null', (tester) async {
    final profile = SharedProfile(id: 'id-1', displayName: 'Ada', username: 'ada');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(_FakeAvatarRenderer())],
        child: MaterialApp(home: SharedProfileScreen(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/sharing/shared_profile_screen_test.dart`
Expected: FAIL — `SharedProfileScreen` doesn't exist.

- [ ] **Step 3: Implement `app/lib/sharing/shared_profile_screen.dart`**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:sharing/sharing.dart';

import '../avatar/avatar_providers.dart';

/// Read-only view of someone else's shared identity — reached via QR scan
/// or NFC tap. Renders their avatar through the same [AvatarRenderer] the
/// app already uses for the owner's own avatar; it's just handed a
/// different [AvatarDefinition].
class SharedProfileScreen extends ConsumerStatefulWidget {
  final SharedProfile profile;

  const SharedProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<SharedProfileScreen> createState() => _SharedProfileScreenState();
}

class _SharedProfileScreenState extends ConsumerState<SharedProfileScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final json = widget.profile.avatarDefinitionJson;
    if (json != null) {
      final definition = AvatarDefinition.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      ref.read(avatarRendererProvider).load(definition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final renderer = ref.watch(avatarRendererProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (profile.avatarDefinitionJson != null)
            SizedBox(height: 240, child: renderer.buildView()),
          const SizedBox(height: 16),
          Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall),
          Text('@${profile.username}'),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          const SizedBox(height: 24),
          if (profile.email != null) Text('Email: ${profile.email}'),
          if (profile.mobile != null) Text('Mobile: ${profile.mobile}'),
          if (profile.xHandle != null) Text('X: ${profile.xHandle}'),
          if (profile.instagramHandle != null) Text('Instagram: ${profile.instagramHandle}'),
          if (profile.website != null) Text('Website: ${profile.website}'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify pass**

Run: `cd app && flutter test test/sharing/shared_profile_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the full suite (this also resolves Task 7's deferred commit)**

Run: `cd app && flutter analyze && flutter test`
Expected: all clean/passing.

- [ ] **Step 6: Commit both this task and Task 7 together**

```bash
git add app/lib/sharing/qr_scan_screen.dart app/lib/sharing/shared_profile_screen.dart app/lib/main.dart app/lib/sharing/share_screen.dart app/test/sharing/shared_profile_screen_test.dart
git commit -m "feat(app): add QR scan screen and Shared Profile view"
```

---

## Task 9: Device spike — verify NFC emulate/read and QR scan on real hardware

**Files:** none (verification task, not code).

This mirrors the avatar renderer's device spike (`docs/architecture/overview.md`'s
"device-verified on Android" section) — the parts of this feature that
can't be unit-tested need to be proven on real devices before this pass is
considered done.

- [ ] **Step 1: Build and run on the Pixel 9 (or any connected Android device)**

```bash
cd app && flutter run -d <device-id>
```

Navigate to the Share tab. Confirm:
- QR code renders and visually looks scannable (not corrupted/blank).
- "Start NFC sharing" button appears and toggles without throwing.

- [ ] **Step 2: Verify QR scan end-to-end, Android device to Android device (or Android to itself via a second app instance/emulator)**

On a second device (or the same device photographing its own screen from
another phone), open the scanner (tap the scan icon on the Share screen)
and scan the first device's QR code. Confirm it navigates to
`SharedProfileScreen` and renders the sender's name, username, bio, and
avatar correctly.

- [ ] **Step 3: Verify NFC emulate → read, Android to Android**

With device A's "Start NFC sharing" active, tap device B against it (with
device B's Share tab open, or anywhere — the `ManagerNfcReader` session
should be listening from `main.dart`, check whether the reader needs to be
explicitly started from a specific screen or should run app-wide; if the
current wiring only starts the reader from a specific screen, note this
as a follow-up rather than expanding scope here). Confirm device B
receives and navigates to the shared profile.

If Task 4's simplified `processCommandApdu` (raw payload bytes, not a
spec-correct NDEF Type 4 Tag exchange) doesn't work against `nfc_manager`'s
reader expectations, this is the point to discover and fix it — document
what was actually needed in `docs/architecture/overview.md` afterward,
the same way the avatar renderer's camera/lighting fixes were documented.

- [ ] **Step 4: Verify NFC read on iOS, if an iPhone is available**

With device A (Android) emulating, bring an iPhone near it. iOS's Core NFC
requires an explicit user-initiated scan session (unlike Android, which
can listen passively) — if the current `ManagerNfcReader` wiring doesn't
trigger a session appropriately on iOS, note this gap; it may need an
explicit "Tap to receive via NFC" button on iOS specifically, rather than
the passive listening Android can do. Resolve or document as a follow-up
based on what's actually observed — don't guess the fix without seeing
the real behavior.

- [ ] **Step 5: Document findings**

Update `docs/architecture/overview.md` with a new subsection (matching the
style of the existing "render path is device-verified on Android, not yet
on iOS" note) recording what was actually verified, what broke, and what
was fixed — this is expected to surface real issues, the same way the
avatar renderer's spike did.

- [ ] **Step 6: Commit the docs update**

```bash
git add docs/architecture/overview.md
git commit -m "docs: record NFC/QR sharing device-verification results"
```
