# Amiro Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Amiro monorepo (Melos + Flutter + Rust), ship local identity create/edit (M1), and prove one end-to-end avatar render/swap/persist pipeline (thin M2 slice), with CI green throughout.

**Architecture:** Melos-managed monorepo. `packages/identity_core` and `packages/avatar_core` are pure-Dart domain models with no Flutter dependency. `packages/avatar_renderer` wraps `thermion_flutter` behind an engine-agnostic interface. `rust/core` owns the `Identity` struct + serde, bridged to Dart via `flutter_rust_bridge`, used for validation/serialization only (Isar remains the actual storage engine, driven from Dart). `app/` composes all packages with Riverpod for state and Isar for local persistence. `packages/sharing`, `packages/nfc`, `packages/qr`, `packages/store` are created as empty stub packages (pubspec + README only) to lock in package boundaries for future milestones.

**Tech Stack:** Flutter (stable channel), Dart, Riverpod, Isar, Melos, Rust (stable), flutter_rust_bridge, thermion_flutter v0.5.0, glTF/GLB assets, GitHub Actions CI, MIT license.

**Spec:** [docs/superpowers/specs/2026-09-22-amiro-foundation-design.md](../specs/2026-09-22-amiro-foundation-design.md)

## Global Constraints

- MIT license (matches `DevelopersCoffee/airo` convention).
- No network calls, no auth, no accounts in this pass — everything local-only.
- No NFC/QR/store/purchase logic implemented — those packages exist only as stubs with README describing the future contract.
- 3D renderer is `thermion_flutter` (pub.dev, v0.5.0) — nothing outside `packages/avatar_renderer` may import it directly.
- `AvatarDefinition` JSON shape must match the PRD's 17-slot conceptual format exactly (body, face, skin, hair, eyes, eyebrows, facialHair, top, bottom, shoes, glasses, earrings, necklace, goldChain, watch, hat, background, effects) even though this pass only populates `body`, `top`, `glasses`.
- Placeholder 3D assets only (blockout/primitive meshes) — not final art, not for public release.
- Creating the public GitHub repo `DevelopersCoffee/amiro` and pushing requires explicit user confirmation at that step (publish action) — do not push without asking first, even though "public" was already chosen as the design answer.
- Every package: `flutter analyze` / `cargo clippy -- -D warnings` clean, tests passing, before commit.

---

## File Structure

```
amiro/
├── melos.yaml
├── pubspec.yaml                       # workspace root (melos bootstrap target)
├── LICENSE
├── README.md
├── .gitignore
├── .github/workflows/ci.yml
├── app/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart                   # MaterialApp + router
│   │   ├── identity/
│   │   │   ├── identity_providers.dart
│   │   │   └── identity_edit_screen.dart
│   │   └── avatar/
│   │       └── avatar_screen.dart
│   └── test/
│       ├── identity/identity_edit_screen_test.dart
│       └── avatar/avatar_screen_test.dart
├── packages/
│   ├── identity_core/
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── identity_core.dart
│   │   │   ├── src/identity.dart
│   │   │   ├── src/privacy_flag.dart
│   │   │   └── src/identity_repository.dart
│   │   └── test/
│   │       ├── identity_test.dart
│   │       └── identity_repository_test.dart
│   ├── avatar_core/
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── avatar_core.dart
│   │   │   └── src/avatar_definition.dart
│   │   └── test/avatar_definition_test.dart
│   ├── avatar_renderer/
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── avatar_renderer.dart
│   │   │   ├── src/avatar_renderer_interface.dart
│   │   │   └── src/thermion_avatar_renderer.dart
│   │   └── test/thermion_avatar_renderer_test.dart
│   ├── sharing/{pubspec.yaml,README.md,lib/sharing.dart}
│   ├── nfc/{pubspec.yaml,README.md,lib/nfc.dart}
│   ├── qr/{pubspec.yaml,README.md,lib/qr.dart}
│   └── store/{pubspec.yaml,README.md,lib/store.dart}
├── rust/core/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       └── identity.rs
├── assets/
│   ├── avatars/body_placeholder.glb   # generated procedurally, see Task 9
│   └── cosmetics/{top_placeholder.glb,glasses_placeholder.glb}
└── docs/
    ├── product/requirements.md
    ├── architecture/overview.md
    ├── protocols/identity-link.md
    ├── protocols/avatar-format.md
    ├── legal/asset-policy.md
    ├── legal/third-party-licenses.md
    └── qa/test-plan.md
```

---

## Task 1: Repo scaffold — license, gitignore, Melos workspace, CI skeleton

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `melos.yaml`
- Create: `pubspec.yaml` (workspace root)
- Create: `README.md`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Produces: a `melos.yaml` with `packages: ['app', 'packages/*']` that every later task's package must be discoverable under.

- [ ] **Step 1: Create `LICENSE`**

Use standard MIT license text, copyright holder `DevelopersCoffee`, year `2026`.

- [ ] **Step 2: Create `.gitignore`**

```gitignore
# Flutter/Dart
.dart_tool/
.packages
build/
*.g.dart
*.freezed.dart
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/

# Rust
rust/**/target/
Cargo.lock

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
```

- [ ] **Step 3: Create `melos.yaml`**

```yaml
name: amiro

packages:
  - app
  - packages/**

command:
  bootstrap:
    runPubGetInParallel: true

scripts:
  analyze:
    run: melos exec -- flutter analyze
    description: Run flutter analyze in every package.

  test:
    run: melos exec --dir-exists=test -- flutter test
    description: Run flutter test in every package that has a test directory.
```

- [ ] **Step 4: Create workspace root `pubspec.yaml`**

```yaml
name: amiro_workspace
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dev_dependencies:
  melos: ^8.9.0
```

- [ ] **Step 5: Create `README.md`**

```markdown
# Amiro

Your digital identity, made wearable. Local-first Flutter app: create a
3D identity, customize it with virtual cosmetics, share it by tapping
phones or showing a QR code.

Monorepo managed with [Melos](https://melos.invertase.dev/). See
[docs/](docs/) for product requirements, architecture, and protocols.

## Getting started

\`\`\`bash
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
\`\`\`

## Repository map

| Path | Owns |
|---|---|
| `app/` | Flutter application shell |
| `packages/identity_core/` | Identity model, privacy flags, local persistence |
| `packages/avatar_core/` | Avatar definition model |
| `packages/avatar_renderer/` | 3D avatar rendering (Filament via thermion_flutter) |
| `packages/sharing/`, `nfc/`, `qr/`, `store/` | Stubs — future milestones |
| `rust/core/` | Rust identity domain struct + serialization |

License: MIT.
```

- [ ] **Step 6: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: dart pub global activate melos
      - run: melos bootstrap
      - run: melos run analyze
      - run: melos run test

  rust:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: rust/core
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - run: cargo test
      - run: cargo clippy -- -D warnings
```

- [ ] **Step 7: Commit**

```bash
git add LICENSE .gitignore melos.yaml pubspec.yaml README.md .github/workflows/ci.yml
git commit -m "chore: scaffold monorepo — license, gitignore, melos workspace, CI skeleton"
```

CI will fail (red) until `app/` and `packages/*` exist — expected until Task 8. Note this in the PR/commit body if opening a PR before then; don't treat red CI as a blocker for early commits on `main` directly (no PR yet at this stage).

---

## Task 2: Rust core — `Identity` struct, validation, serde round-trip

**Files:**
- Create: `rust/core/Cargo.toml`
- Create: `rust/core/src/lib.rs`
- Create: `rust/core/src/identity.rs`

**Interfaces:**
- Produces: `amiro_core::identity::Identity { id: String, display_name: String, username: String, bio: Option<String>, mobile: Option<String>, email: Option<String>, x_handle: Option<String>, instagram_handle: Option<String>, website: Option<String> }`, `Identity::new(id, display_name, username) -> Result<Identity, IdentityError>`, `Identity::validate(&self) -> Result<(), IdentityError>`.

- [ ] **Step 1: Create `rust/core/Cargo.toml`**

```toml
[package]
name = "amiro_core"
version = "0.1.0"
edition = "2021"
license = "MIT"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[dev-dependencies]
```

- [ ] **Step 2: Write failing test in `rust/core/src/identity.rs`**

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Identity {
    pub id: String,
    pub display_name: String,
    pub username: String,
    pub bio: Option<String>,
    pub mobile: Option<String>,
    pub email: Option<String>,
    pub x_handle: Option<String>,
    pub instagram_handle: Option<String>,
    pub website: Option<String>,
}

#[derive(Debug, PartialEq)]
pub enum IdentityError {
    EmptyDisplayName,
    EmptyUsername,
    UsernameHasSpaces,
}

impl Identity {
    pub fn new(id: String, display_name: String, username: String) -> Result<Self, IdentityError> {
        let identity = Identity {
            id,
            display_name,
            username,
            bio: None,
            mobile: None,
            email: None,
            x_handle: None,
            instagram_handle: None,
            website: None,
        };
        identity.validate()?;
        Ok(identity)
    }

    pub fn validate(&self) -> Result<(), IdentityError> {
        if self.display_name.trim().is_empty() {
            return Err(IdentityError::EmptyDisplayName);
        }
        if self.username.trim().is_empty() {
            return Err(IdentityError::EmptyUsername);
        }
        if self.username.contains(' ') {
            return Err(IdentityError::UsernameHasSpaces);
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_valid_identity_succeeds() {
        let identity = Identity::new("id-1".into(), "Uday".into(), "uday".into()).unwrap();
        assert_eq!(identity.display_name, "Uday");
        assert_eq!(identity.username, "uday");
        assert_eq!(identity.bio, None);
    }

    #[test]
    fn new_with_empty_display_name_fails() {
        let result = Identity::new("id-1".into(), "".into(), "uday".into());
        assert_eq!(result, Err(IdentityError::EmptyDisplayName));
    }

    #[test]
    fn new_with_empty_username_fails() {
        let result = Identity::new("id-1".into(), "Uday".into(), "".into());
        assert_eq!(result, Err(IdentityError::EmptyUsername));
    }

    #[test]
    fn username_with_spaces_fails() {
        let result = Identity::new("id-1".into(), "Uday".into(), "uday chauhan".into());
        assert_eq!(result, Err(IdentityError::UsernameHasSpaces));
    }

    #[test]
    fn serde_round_trip_preserves_all_fields() {
        let mut identity = Identity::new("id-1".into(), "Uday".into(), "uday".into()).unwrap();
        identity.bio = Some("Software Engineer".into());
        identity.email = Some("coffee.devloper@gmail.com".into());

        let json = serde_json::to_string(&identity).unwrap();
        let restored: Identity = serde_json::from_str(&json).unwrap();

        assert_eq!(identity, restored);
    }
}
```

- [ ] **Step 3: Create `rust/core/src/lib.rs`**

```rust
pub mod identity;
```

- [ ] **Step 4: Run tests to verify pass**

Run: `cd rust/core && cargo test`
Expected: 5 tests pass (`new_valid_identity_succeeds`, `new_with_empty_display_name_fails`, `new_with_empty_username_fails`, `username_with_spaces_fails`, `serde_round_trip_preserves_all_fields`).

- [ ] **Step 5: Run clippy**

Run: `cd rust/core && cargo clippy -- -D warnings`
Expected: no warnings.

- [ ] **Step 6: Commit**

```bash
git add rust/core
git commit -m "feat(rust-core): add Identity struct with validation and serde round-trip"
```

---

## Task 3: `identity_core` package — Dart `Identity` model + `PrivacyFlag`

**Files:**
- Create: `packages/identity_core/pubspec.yaml`
- Create: `packages/identity_core/lib/identity_core.dart`
- Create: `packages/identity_core/lib/src/privacy_flag.dart`
- Create: `packages/identity_core/lib/src/identity.dart`
- Test: `packages/identity_core/test/identity_test.dart`

**Interfaces:**
- Consumes: nothing (pure Dart, no dependency on Task 2's Rust code in this pass — the Rust core is exercised independently via `cargo test`; Dart↔Rust bridging is future work, not wired into the app this pass, since `flutter_rust_bridge` codegen adds a build step disproportionate to what M1 needs. Flagged as follow-up in Task 12 docs.)
- Produces: `class PrivacyFlag { final bool isPublic; const PrivacyFlag(this.isPublic); }`, `class Identity { final String id; final String displayName; final String username; final String? bio; final String? mobile; final String? email; final String? xHandle; final String? instagramHandle; final String? website; final Map<String, PrivacyFlag> privacy; Identity({...}); Identity copyWith({...}); Map<String, dynamic> toJson(); factory Identity.fromJson(Map<String, dynamic> json); }`.

- [ ] **Step 1: Create `packages/identity_core/pubspec.yaml`**

```yaml
name: identity_core
description: Identity model and privacy flags for Amiro.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

Also create `packages/identity_core/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Write failing test in `packages/identity_core/test/identity_test.dart`**

```dart
import 'package:identity_core/identity_core.dart';
import 'package:test/test.dart';

void main() {
  group('Identity', () {
    test('constructs with required fields and defaults', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
      );

      expect(identity.displayName, 'Uday');
      expect(identity.username, 'uday');
      expect(identity.bio, isNull);
      expect(identity.privacy, isEmpty);
    });

    test('copyWith overrides only given fields', () {
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      final updated = identity.copyWith(bio: 'Software Engineer');

      expect(updated.bio, 'Software Engineer');
      expect(updated.displayName, 'Uday');
      expect(updated.id, 'id-1');
    });

    test('toJson/fromJson round trip preserves all fields and privacy map', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'email': PrivacyFlag(false),
          'bio': PrivacyFlag(true),
        },
      );

      final restored = Identity.fromJson(identity.toJson());

      expect(restored.id, identity.id);
      expect(restored.displayName, identity.displayName);
      expect(restored.bio, identity.bio);
      expect(restored.email, identity.email);
      expect(restored.privacy['email']!.isPublic, false);
      expect(restored.privacy['bio']!.isPublic, true);
    });

    test('publicFields returns only fields flagged public', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'email': PrivacyFlag(false),
          'bio': PrivacyFlag(true),
        },
      );

      final publicFields = identity.publicFields();

      expect(publicFields.containsKey('bio'), isTrue);
      expect(publicFields.containsKey('email'), isFalse);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/identity_core && dart pub get && dart test`
Expected: FAIL — `identity_core` library doesn't exist yet.

- [ ] **Step 4: Implement `packages/identity_core/lib/src/privacy_flag.dart`**

```dart
/// Whether a single identity field is visible in the public profile.
class PrivacyFlag {
  final bool isPublic;

  const PrivacyFlag(this.isPublic);

  factory PrivacyFlag.fromJson(bool json) => PrivacyFlag(json);

  bool toJson() => isPublic;
}
```

- [ ] **Step 5: Implement `packages/identity_core/lib/src/identity.dart`**

```dart
import 'privacy_flag.dart';

/// A user's Amiro identity: display info, contact fields, and per-field
/// privacy flags controlling what appears on the public profile.
class Identity {
  final String id;
  final String displayName;
  final String username;
  final String? bio;
  final String? mobile;
  final String? email;
  final String? xHandle;
  final String? instagramHandle;
  final String? website;
  final String? avatarDefinitionId;
  final Map<String, PrivacyFlag> privacy;

  const Identity({
    required this.id,
    required this.displayName,
    required this.username,
    this.bio,
    this.mobile,
    this.email,
    this.xHandle,
    this.instagramHandle,
    this.website,
    this.avatarDefinitionId,
    this.privacy = const {},
  });

  Identity copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? mobile,
    String? email,
    String? xHandle,
    String? instagramHandle,
    String? website,
    String? avatarDefinitionId,
    Map<String, PrivacyFlag>? privacy,
  }) {
    return Identity(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      xHandle: xHandle ?? this.xHandle,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      website: website ?? this.website,
      avatarDefinitionId: avatarDefinitionId ?? this.avatarDefinitionId,
      privacy: privacy ?? this.privacy,
    );
  }

  /// Returns only the string fields whose privacy flag is public.
  Map<String, String> publicFields() {
    final all = <String, String?>{
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'mobile': mobile,
      'email': email,
      'xHandle': xHandle,
      'instagramHandle': instagramHandle,
      'website': website,
    };

    final result = <String, String>{};
    all.forEach((key, value) {
      if (value == null) return;
      final flag = privacy[key];
      // Fields with no explicit flag default to private.
      if (flag != null && flag.isPublic) {
        result[key] = value;
      }
    });
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'mobile': mobile,
      'email': email,
      'xHandle': xHandle,
      'instagramHandle': instagramHandle,
      'website': website,
      'avatarDefinitionId': avatarDefinitionId,
      'privacy': privacy.map((key, flag) => MapEntry(key, flag.toJson())),
    };
  }

  factory Identity.fromJson(Map<String, dynamic> json) {
    final privacyJson = (json['privacy'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Identity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      xHandle: json['xHandle'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      website: json['website'] as String?,
      avatarDefinitionId: json['avatarDefinitionId'] as String?,
      privacy: privacyJson.map(
        (key, value) => MapEntry(key, PrivacyFlag.fromJson(value as bool)),
      ),
    );
  }
}
```

- [ ] **Step 6: Create `packages/identity_core/lib/identity_core.dart`**

```dart
export 'src/identity.dart';
export 'src/privacy_flag.dart';
```

- [ ] **Step 7: Run tests to verify pass**

Run: `cd packages/identity_core && dart test`
Expected: PASS (4 tests).

- [ ] **Step 8: Commit**

```bash
git add packages/identity_core
git commit -m "feat(identity_core): add Identity model with privacy flags and JSON round-trip"
```

---

## Task 4: `identity_core` — `IdentityRepository` interface + Isar implementation

**Files:**
- Modify: `packages/identity_core/pubspec.yaml`
- Create: `packages/identity_core/lib/src/identity_repository.dart`
- Create: `packages/identity_core/lib/src/isar_identity_repository.dart`
- Create: `packages/identity_core/lib/src/identity_isar_schema.dart`
- Test: `packages/identity_core/test/isar_identity_repository_test.dart`

**Interfaces:**
- Consumes: `Identity`, `PrivacyFlag` from Task 3.
- Produces: `abstract class IdentityRepository { Future<Identity?> getCurrent(); Future<void> save(Identity identity); Future<void> clear(); }`, `class IsarIdentityRepository implements IdentityRepository`, `Future<Isar> openIdentityIsar({String? directory})`.

- [ ] **Step 1: Add Isar dependencies to `packages/identity_core/pubspec.yaml`**

```yaml
dependencies:
  isar: ^3.1.8
  isar_flutter_libs: ^3.1.8
  path_provider: ^2.1.4

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
  isar_generator: ^3.1.8
  build_runner: ^2.4.9
```

- [ ] **Step 2: Define the repository interface — `packages/identity_core/lib/src/identity_repository.dart`**

```dart
import 'identity.dart';

/// Storage boundary for a device's single local Identity.
///
/// This pass supports exactly one identity per device (no multi-profile,
/// no accounts). Swapping the backing store later only touches
/// implementations of this interface.
abstract class IdentityRepository {
  Future<Identity?> getCurrent();
  Future<void> save(Identity identity);
  Future<void> clear();
}
```

- [ ] **Step 3: Define the Isar collection schema — `packages/identity_core/lib/src/identity_isar_schema.dart`**

```dart
import 'package:isar/isar.dart';

part 'identity_isar_schema.g.dart';

@collection
class IdentityRecord {
  Id isarId = 0; // fixed id: single-row table for the device's one identity

  late String id;
  late String displayName;
  late String username;
  String? bio;
  String? mobile;
  String? email;
  String? xHandle;
  String? instagramHandle;
  String? website;
  String? avatarDefinitionId;

  /// JSON-encoded `Map<String, bool>` of field name -> isPublic.
  late String privacyJson;
}
```

- [ ] **Step 4: Write failing test in `packages/identity_core/test/isar_identity_repository_test.dart`**

```dart
import 'dart:io';

import 'package:identity_core/identity_core.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late IsarIdentityRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('identity_core_test');
    isar = await openIdentityIsar(directory: tempDir.path);
    repository = IsarIdentityRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    await tempDir.delete(recursive: true);
  });

  test('getCurrent returns null when nothing saved', () async {
    expect(await repository.getCurrent(), isNull);
  });

  test('save then getCurrent returns the saved identity', () async {
    final identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      bio: 'Software Engineer',
      privacy: const {'bio': PrivacyFlag(true)},
    );

    await repository.save(identity);
    final restored = await repository.getCurrent();

    expect(restored, isNotNull);
    expect(restored!.displayName, 'Uday');
    expect(restored.bio, 'Software Engineer');
    expect(restored.privacy['bio']!.isPublic, true);
  });

  test('save overwrites the previous identity (single-row semantics)', () async {
    await repository.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));
    await repository.save(Identity(id: 'id-1', displayName: 'Uday C', username: 'uday'));

    final restored = await repository.getCurrent();
    expect(restored!.displayName, 'Uday C');
  });

  test('clear removes the saved identity', () async {
    await repository.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));
    await repository.clear();

    expect(await repository.getCurrent(), isNull);
  });
}
```

- [ ] **Step 5: Run test to verify it fails**

Run: `cd packages/identity_core && dart run build_runner build --delete-conflicting-outputs && dart test`
Expected: FAIL — `IsarIdentityRepository` / `openIdentityIsar` undefined.

- [ ] **Step 6: Implement `packages/identity_core/lib/src/isar_identity_repository.dart`**

```dart
import 'dart:convert';

import 'package:isar/isar.dart';

import 'identity.dart';
import 'identity_isar_schema.dart';
import 'identity_repository.dart';
import 'privacy_flag.dart';

const _kSingleRowId = 0;

Future<Isar> openIdentityIsar({String? directory}) {
  return Isar.open(
    [IdentityRecordSchema],
    directory: directory ?? '.',
  );
}

class IsarIdentityRepository implements IdentityRepository {
  final Isar _isar;

  IsarIdentityRepository(this._isar);

  @override
  Future<Identity?> getCurrent() async {
    final record = await _isar.identityRecords.get(_kSingleRowId);
    if (record == null) return null;
    return _toIdentity(record);
  }

  @override
  Future<void> save(Identity identity) async {
    final record = _toRecord(identity);
    await _isar.writeTxn(() => _isar.identityRecords.put(record));
  }

  @override
  Future<void> clear() async {
    await _isar.writeTxn(() => _isar.identityRecords.delete(_kSingleRowId));
  }

  IdentityRecord _toRecord(Identity identity) {
    final privacyMap = identity.privacy.map((k, v) => MapEntry(k, v.isPublic));
    return IdentityRecord()
      ..isarId = _kSingleRowId
      ..id = identity.id
      ..displayName = identity.displayName
      ..username = identity.username
      ..bio = identity.bio
      ..mobile = identity.mobile
      ..email = identity.email
      ..xHandle = identity.xHandle
      ..instagramHandle = identity.instagramHandle
      ..website = identity.website
      ..avatarDefinitionId = identity.avatarDefinitionId
      ..privacyJson = jsonEncode(privacyMap);
  }

  Identity _toIdentity(IdentityRecord record) {
    final privacyMap = (jsonDecode(record.privacyJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, PrivacyFlag(v as bool)));
    return Identity(
      id: record.id,
      displayName: record.displayName,
      username: record.username,
      bio: record.bio,
      mobile: record.mobile,
      email: record.email,
      xHandle: record.xHandle,
      instagramHandle: record.instagramHandle,
      website: record.website,
      avatarDefinitionId: record.avatarDefinitionId,
      privacy: privacyMap,
    );
  }
}
```

- [ ] **Step 7: Export new symbols in `packages/identity_core/lib/identity_core.dart`**

```dart
export 'src/identity.dart';
export 'src/privacy_flag.dart';
export 'src/identity_repository.dart';
export 'src/isar_identity_repository.dart';
```

- [ ] **Step 8: Run tests to verify pass**

Run: `cd packages/identity_core && dart test`
Expected: PASS (4 new tests, 8 total).

- [ ] **Step 9: Commit**

```bash
git add packages/identity_core
git commit -m "feat(identity_core): add IdentityRepository with Isar-backed implementation"
```

---

## Task 5: `avatar_core` package — `AvatarDefinition` model

**Files:**
- Create: `packages/avatar_core/pubspec.yaml`
- Create: `packages/avatar_core/lib/avatar_core.dart`
- Create: `packages/avatar_core/lib/src/avatar_definition.dart`
- Test: `packages/avatar_core/test/avatar_definition_test.dart`

**Interfaces:**
- Produces: `class AvatarDefinition { final String id; final String? body, face, skin, hair, eyes, eyebrows, facialHair, top, bottom, shoes, glasses, earrings, necklace, goldChain, watch, hat, background, effects; AvatarDefinition({...}); AvatarDefinition copyWithSlot(String slot, String? assetId); Map<String, dynamic> toJson(); factory AvatarDefinition.fromJson(Map<String, dynamic> json); static const List<String> slots; }`.

- [ ] **Step 1: Create `packages/avatar_core/pubspec.yaml`**

```yaml
name: avatar_core
description: Avatar definition model for Amiro.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

Also create `packages/avatar_core/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Write failing test in `packages/avatar_core/test/avatar_definition_test.dart`**

```dart
import 'package:avatar_core/avatar_core.dart';
import 'package:test/test.dart';

void main() {
  group('AvatarDefinition', () {
    test('slots contains all 17 PRD-defined slots', () {
      expect(AvatarDefinition.slots, [
        'body',
        'face',
        'skin',
        'hair',
        'eyes',
        'eyebrows',
        'facialHair',
        'top',
        'bottom',
        'shoes',
        'glasses',
        'earrings',
        'necklace',
        'goldChain',
        'watch',
        'hat',
        'background',
        'effects',
      ]);
    });

    test('constructs with only the slots this pass populates', () {
      const def = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder');

      expect(def.body, 'body_placeholder');
      expect(def.top, isNull);
      expect(def.glasses, isNull);
    });

    test('copyWithSlot updates exactly one slot and leaves others untouched', () {
      const def = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_01');

      final updated = def.copyWithSlot('glasses', 'glasses_01');

      expect(updated.glasses, 'glasses_01');
      expect(updated.top, 'top_01');
      expect(updated.body, 'body_placeholder');
    });

    test('copyWithSlot rejects an unknown slot name', () {
      const def = AvatarDefinition(id: 'avatar-1');
      expect(() => def.copyWithSlot('cape', 'cape_01'), throwsArgumentError);
    });

    test('toJson/fromJson round trip', () {
      const def = AvatarDefinition(
        id: 'avatar-1',
        body: 'body_placeholder',
        top: 'top_01',
        glasses: 'glasses_01',
      );

      final restored = AvatarDefinition.fromJson(def.toJson());

      expect(restored.id, def.id);
      expect(restored.body, def.body);
      expect(restored.top, def.top);
      expect(restored.glasses, def.glasses);
      expect(restored.hat, isNull);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/avatar_core && dart pub get && dart test`
Expected: FAIL — `avatar_core` library doesn't exist.

- [ ] **Step 4: Implement `packages/avatar_core/lib/src/avatar_definition.dart`**

```dart
/// An avatar's equipped cosmetics, one asset id per slot.
///
/// Slot list matches the PRD's full 17-slot avatar system exactly, even
/// though this pass only ever populates `body`, `top`, and `glasses` —
/// this avoids a schema migration when later milestones add real
/// cosmetics for the remaining slots.
class AvatarDefinition {
  static const List<String> slots = [
    'body',
    'face',
    'skin',
    'hair',
    'eyes',
    'eyebrows',
    'facialHair',
    'top',
    'bottom',
    'shoes',
    'glasses',
    'earrings',
    'necklace',
    'goldChain',
    'watch',
    'hat',
    'background',
    'effects',
  ];

  final String id;
  final String? body;
  final String? face;
  final String? skin;
  final String? hair;
  final String? eyes;
  final String? eyebrows;
  final String? facialHair;
  final String? top;
  final String? bottom;
  final String? shoes;
  final String? glasses;
  final String? earrings;
  final String? necklace;
  final String? goldChain;
  final String? watch;
  final String? hat;
  final String? background;
  final String? effects;

  const AvatarDefinition({
    required this.id,
    this.body,
    this.face,
    this.skin,
    this.hair,
    this.eyes,
    this.eyebrows,
    this.facialHair,
    this.top,
    this.bottom,
    this.shoes,
    this.glasses,
    this.earrings,
    this.necklace,
    this.goldChain,
    this.watch,
    this.hat,
    this.background,
    this.effects,
  });

  Map<String, String?> _asMap() => {
        'body': body,
        'face': face,
        'skin': skin,
        'hair': hair,
        'eyes': eyes,
        'eyebrows': eyebrows,
        'facialHair': facialHair,
        'top': top,
        'bottom': bottom,
        'shoes': shoes,
        'glasses': glasses,
        'earrings': earrings,
        'necklace': necklace,
        'goldChain': goldChain,
        'watch': watch,
        'hat': hat,
        'background': background,
        'effects': effects,
      };

  /// Returns a copy with exactly one slot replaced. Throws [ArgumentError]
  /// if [slot] is not one of [slots].
  AvatarDefinition copyWithSlot(String slot, String? assetId) {
    if (!slots.contains(slot)) {
      throw ArgumentError.value(slot, 'slot', 'must be one of AvatarDefinition.slots');
    }
    final current = _asMap();
    current[slot] = assetId;
    return AvatarDefinition(
      id: id,
      body: current['body'],
      face: current['face'],
      skin: current['skin'],
      hair: current['hair'],
      eyes: current['eyes'],
      eyebrows: current['eyebrows'],
      facialHair: current['facialHair'],
      top: current['top'],
      bottom: current['bottom'],
      shoes: current['shoes'],
      glasses: current['glasses'],
      earrings: current['earrings'],
      necklace: current['necklace'],
      goldChain: current['goldChain'],
      watch: current['watch'],
      hat: current['hat'],
      background: current['background'],
      effects: current['effects'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ..._asMap()};

  factory AvatarDefinition.fromJson(Map<String, dynamic> json) {
    return AvatarDefinition(
      id: json['id'] as String,
      body: json['body'] as String?,
      face: json['face'] as String?,
      skin: json['skin'] as String?,
      hair: json['hair'] as String?,
      eyes: json['eyes'] as String?,
      eyebrows: json['eyebrows'] as String?,
      facialHair: json['facialHair'] as String?,
      top: json['top'] as String?,
      bottom: json['bottom'] as String?,
      shoes: json['shoes'] as String?,
      glasses: json['glasses'] as String?,
      earrings: json['earrings'] as String?,
      necklace: json['necklace'] as String?,
      goldChain: json['goldChain'] as String?,
      watch: json['watch'] as String?,
      hat: json['hat'] as String?,
      background: json['background'] as String?,
      effects: json['effects'] as String?,
    );
  }
}
```

- [ ] **Step 5: Create `packages/avatar_core/lib/avatar_core.dart`**

```dart
export 'src/avatar_definition.dart';
```

- [ ] **Step 6: Run tests to verify pass**

Run: `cd packages/avatar_core && dart test`
Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add packages/avatar_core
git commit -m "feat(avatar_core): add AvatarDefinition model with full 17-slot schema"
```

---

## Task 6: `avatar_renderer` package — interface + Thermion implementation

**Files:**
- Create: `packages/avatar_renderer/pubspec.yaml`
- Create: `packages/avatar_renderer/lib/avatar_renderer.dart`
- Create: `packages/avatar_renderer/lib/src/avatar_renderer_interface.dart`
- Create: `packages/avatar_renderer/lib/src/thermion_avatar_renderer.dart`
- Create: `packages/avatar_renderer/lib/src/avatar_asset_resolver.dart`
- Test: `packages/avatar_renderer/test/avatar_asset_resolver_test.dart`
- Test: `packages/avatar_renderer/test/thermion_avatar_renderer_test.dart`

**Interfaces:**
- Consumes: `AvatarDefinition` from Task 5.
- Produces: `abstract class AvatarRenderer { Future<void> load(AvatarDefinition definition); Widget buildView(); Future<void> updateSlot(String slot, String? assetId); AvatarDefinition get current; Future<void> dispose(); }`, `class ThermionAvatarRenderer implements AvatarRenderer`, `String resolveAssetPath(String slot, String assetId)`.

**Note:** `thermion_flutter` requires a live Flutter engine (platform channels) to actually render, so its true rendering path is exercised in Task 10's app-level widget/integration test, not here. This task's `thermion_avatar_renderer_test.dart` tests the parts that don't require a live engine: state tracking (`current`) and slot-update bookkeeping, using a thin seam (`FilamentSurface` abstraction) so the engine call itself can be faked in a unit test.

- [ ] **Step 1: Create `packages/avatar_renderer/pubspec.yaml`**

```yaml
name: avatar_renderer
description: Avatar rendering interface for Amiro, backed by Filament via thermion_flutter.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  avatar_core:
    path: ../avatar_core
  thermion_flutter: ^0.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0
```

Also create `packages/avatar_renderer/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Define the resolver test — `packages/avatar_renderer/test/avatar_asset_resolver_test.dart`**

```dart
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveAssetPath maps slot + asset id to a packaged asset path', () {
    expect(
      resolveAssetPath('body', 'body_placeholder'),
      'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
    );
    expect(
      resolveAssetPath('top', 'top_placeholder'),
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    );
    expect(
      resolveAssetPath('glasses', 'glasses_placeholder'),
      'packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb',
    );
  });

  test('resolveAssetPath throws for an unknown slot', () {
    expect(() => resolveAssetPath('cape', 'cape_01'), throwsArgumentError);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd packages/avatar_renderer && flutter pub get && flutter test test/avatar_asset_resolver_test.dart`
Expected: FAIL — `resolveAssetPath` undefined.

- [ ] **Step 4: Implement `packages/avatar_renderer/lib/src/avatar_asset_resolver.dart`**

```dart
/// Maps a (slot, assetId) pair to the packaged glTF/GLB asset path.
///
/// `body` renders from `assets/avatars/`; every other slot renders from
/// `assets/cosmetics/`. This pass only ships placeholder assets for
/// `body`, `top`, and `glasses` (see Task 9).
String resolveAssetPath(String slot, String assetId) {
  const validSlots = {
    'body',
    'face',
    'skin',
    'hair',
    'eyes',
    'eyebrows',
    'facialHair',
    'top',
    'bottom',
    'shoes',
    'glasses',
    'earrings',
    'necklace',
    'goldChain',
    'watch',
    'hat',
    'background',
    'effects',
  };
  if (!validSlots.contains(slot)) {
    throw ArgumentError.value(slot, 'slot', 'unknown avatar slot');
  }
  final folder = slot == 'body' ? 'avatars' : 'cosmetics';
  return 'packages/avatar_renderer/assets/$folder/$assetId.glb';
}
```

- [ ] **Step 5: Run resolver test to verify pass**

Run: `cd packages/avatar_renderer && flutter test test/avatar_asset_resolver_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Define the renderer interface — `packages/avatar_renderer/lib/src/avatar_renderer_interface.dart`**

```dart
import 'package:flutter/widgets.dart';

import 'package:avatar_core/avatar_core.dart';

/// Engine-agnostic avatar rendering boundary. Nothing outside this
/// package may import `thermion_flutter` (or any future engine)
/// directly — swap the concrete implementation here without touching
/// callers.
abstract class AvatarRenderer {
  /// The definition currently loaded, or `null` before the first [load].
  AvatarDefinition? get current;

  /// Loads a definition, rendering all populated slots.
  Future<void> load(AvatarDefinition definition);

  /// Returns the widget that displays the live render. Must be called
  /// after [load].
  Widget buildView();

  /// Swaps a single slot on the currently loaded definition and
  /// re-renders. Throws [StateError] if called before [load].
  Future<void> updateSlot(String slot, String? assetId);

  /// Releases engine resources. Must be called when the view is
  /// removed from the tree.
  Future<void> dispose();
}
```

- [ ] **Step 7: Write failing test for state-tracking behavior — `packages/avatar_renderer/test/thermion_avatar_renderer_test.dart`**

```dart
import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:avatar_renderer/src/thermion_avatar_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes the Filament engine calls so this test doesn't require a live
/// platform view. Real engine wiring is exercised in the app's
/// integration test (Task 10).
class _FakeFilamentSurface implements FilamentSurface {
  final List<String> loadedPaths = [];

  @override
  Future<void> loadModel(String assetPath) async {
    loadedPaths.add(assetPath);
  }

  @override
  Future<void> removeModel(String assetPath) async {
    loadedPaths.remove(assetPath);
  }
}

void main() {
  late _FakeFilamentSurface surface;
  late ThermionAvatarRenderer renderer;

  setUp(() {
    surface = _FakeFilamentSurface();
    renderer = ThermionAvatarRenderer(surface: surface);
  });

  test('current is null before load', () {
    expect(renderer.current, isNull);
  });

  test('load sets current and loads each populated slot as a model', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');

    await renderer.load(definition);

    expect(renderer.current, definition);
    expect(surface.loadedPaths, containsAll([
      'packages/avatar_renderer/assets/avatars/body_placeholder.glb',
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    ]));
  });

  test('updateSlot swaps the model for that slot only', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');
    await renderer.load(definition);

    await renderer.updateSlot('glasses', 'glasses_placeholder');

    expect(renderer.current!.glasses, 'glasses_placeholder');
    expect(surface.loadedPaths, contains(
      'packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb',
    ));
  });

  test('updateSlot with null removes the previously loaded model for that slot', () async {
    const definition = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_placeholder');
    await renderer.load(definition);

    await renderer.updateSlot('top', null);

    expect(renderer.current!.top, isNull);
    expect(surface.loadedPaths, isNot(contains(
      'packages/avatar_renderer/assets/cosmetics/top_placeholder.glb',
    )));
  });

  test('updateSlot before load throws StateError', () {
    expect(() => renderer.updateSlot('top', 'top_placeholder'), throwsStateError);
  });
}
```

- [ ] **Step 8: Run test to verify it fails**

Run: `cd packages/avatar_renderer && flutter test test/thermion_avatar_renderer_test.dart`
Expected: FAIL — `ThermionAvatarRenderer` / `FilamentSurface` undefined.

- [ ] **Step 9: Implement `packages/avatar_renderer/lib/src/thermion_avatar_renderer.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:thermion_flutter/thermion_flutter.dart' as thermion;

import 'package:avatar_core/avatar_core.dart';

import 'avatar_asset_resolver.dart';
import 'avatar_renderer_interface.dart';

/// Thin seam over the Filament surface so slot-swap bookkeeping is unit
/// testable without a live platform view.
abstract class FilamentSurface {
  Future<void> loadModel(String assetPath);
  Future<void> removeModel(String assetPath);
}

/// Real [FilamentSurface] backed by thermion_flutter's viewer.
class ThermionFilamentSurface implements FilamentSurface {
  final thermion.ThermionViewer _viewer;

  ThermionFilamentSurface(this._viewer);

  @override
  Future<void> loadModel(String assetPath) => _viewer.loadGlb(assetPath);

  @override
  Future<void> removeModel(String assetPath) => _viewer.removeAsset(assetPath);
}

class ThermionAvatarRenderer implements AvatarRenderer {
  final FilamentSurface surface;
  AvatarDefinition? _current;

  ThermionAvatarRenderer({required this.surface});

  @override
  AvatarDefinition? get current => _current;

  @override
  Future<void> load(AvatarDefinition definition) async {
    for (final slot in AvatarDefinition.slots) {
      final assetId = _slotValue(definition, slot);
      if (assetId != null) {
        await surface.loadModel(resolveAssetPath(slot, assetId));
      }
    }
    _current = definition;
  }

  @override
  Future<void> updateSlot(String slot, String? assetId) async {
    final loaded = _current;
    if (loaded == null) {
      throw StateError('updateSlot called before load()');
    }

    final previousAssetId = _slotValue(loaded, slot);
    if (previousAssetId != null) {
      await surface.removeModel(resolveAssetPath(slot, previousAssetId));
    }
    if (assetId != null) {
      await surface.loadModel(resolveAssetPath(slot, assetId));
    }

    _current = loaded.copyWithSlot(slot, assetId);
  }

  @override
  Widget buildView() {
    return const thermion.ThermionWidget();
  }

  @override
  Future<void> dispose() async {
    _current = null;
  }

  String? _slotValue(AvatarDefinition def, String slot) {
    final json = def.toJson();
    return json[slot] as String?;
  }
}
```

- [ ] **Step 10: Create `packages/avatar_renderer/lib/avatar_renderer.dart`**

```dart
export 'src/avatar_renderer_interface.dart';
export 'src/avatar_asset_resolver.dart';
export 'src/thermion_avatar_renderer.dart' show ThermionAvatarRenderer, ThermionFilamentSurface, FilamentSurface;
```

- [ ] **Step 11: Run tests to verify pass**

Run: `cd packages/avatar_renderer && flutter test`
Expected: PASS (6 tests total).

If `thermion_flutter`'s actual API names (`ThermionViewer`, `loadGlb`, `removeAsset`, `ThermionWidget`) differ from what's assumed above, check the installed package's exported API (`flutter pub deps` then read `.dart_tool/package_config.json` path to `thermion_flutter`'s `lib/thermion_flutter.dart`) and adjust `ThermionFilamentSurface`/`buildView()` to match — the test suite in this task doesn't exercise those calls directly (see the seam note above), so this adjustment is isolated to Step 9 and doesn't ripple elsewhere.

- [ ] **Step 12: Commit**

```bash
git add packages/avatar_renderer
git commit -m "feat(avatar_renderer): add AvatarRenderer interface and Thermion implementation"
```

---

## Task 7: Stub packages — `sharing`, `nfc`, `qr`, `store`

**Files:**
- Create: `packages/sharing/pubspec.yaml`, `packages/sharing/README.md`, `packages/sharing/lib/sharing.dart`
- Create: `packages/nfc/pubspec.yaml`, `packages/nfc/README.md`, `packages/nfc/lib/nfc.dart`
- Create: `packages/qr/pubspec.yaml`, `packages/qr/README.md`, `packages/qr/lib/qr.dart`
- Create: `packages/store/pubspec.yaml`, `packages/store/README.md`, `packages/store/lib/store.dart`

**Interfaces:**
- Produces: four empty-but-valid Dart packages, each importable (`import 'package:sharing/sharing.dart';` etc.) even though they export nothing yet — this proves the Melos workspace resolves them and CI stays green as future milestones fill them in without moving files.

- [ ] **Step 1: Create `packages/sharing/pubspec.yaml`**

```yaml
name: sharing
description: Amiro identity sharing orchestration (NFC/QR/deep-link). Not yet implemented.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dev_dependencies:
  lints: ^4.0.0
```

- [ ] **Step 2: Create `packages/sharing/lib/sharing.dart`**

```dart
// Not yet implemented. See README.md for the planned public interface.
```

- [ ] **Step 3: Create `packages/sharing/README.md`**

```markdown
# sharing

**Status: stub — not implemented.**

Owns the orchestration between `nfc`, `qr`, and deep-link resolution:
picking which channel to use, building the compact identity payload
(`https://id.amiro.app/u/<id>`), and routing an incoming tap/scan to
either the native profile screen (app installed) or a signal to open
the web fallback.

Planned interface (from `docs/superpowers/specs/2026-09-22-amiro-foundation-design.md`
and the product PRD's NFC/QR sections):

- `ShareableIdentityLink buildShareLink(String identityId)`
- `Stream<IncomingShare> listenForIncomingShares()`

Implemented in a future milestone (M4, Sharing), by the Sharing agent.
```

- [ ] **Step 4: Repeat Steps 1-3 for `packages/nfc/`**

`packages/nfc/pubspec.yaml`:

```yaml
name: nfc
description: NFC read/write for Amiro identity sharing. Not yet implemented.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dev_dependencies:
  lints: ^4.0.0
```

`packages/nfc/lib/nfc.dart`:

```dart
// Not yet implemented. See README.md for the planned public interface.
```

`packages/nfc/README.md`:

```markdown
# nfc

**Status: stub — not implemented.**

Owns reading and writing the compact identity deep-link payload over
NFC (tap-to-share). Planned interface:

- `Future<void> writeIdentityPayload(String url)`
- `Stream<String> readIncomingPayload()`

Implemented in a future milestone (M4, Sharing), by the NFC/Sharing agent.
```

- [ ] **Step 5: Repeat for `packages/qr/`**

`packages/qr/pubspec.yaml`:

```yaml
name: qr
description: QR generation/scanning for Amiro identity sharing. Not yet implemented.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dev_dependencies:
  lints: ^4.0.0
```

`packages/qr/lib/qr.dart`:

```dart
// Not yet implemented. See README.md for the planned public interface.
```

`packages/qr/README.md`:

```markdown
# qr

**Status: stub — not implemented.**

Owns generating a QR code for the identity share link and scanning an
incoming QR code. Planned interface:

- `Widget buildIdentityQrCode(String url)`
- `Future<String?> scanQrCode()`

Implemented in a future milestone (M4, Sharing), by the NFC/Sharing agent.
```

- [ ] **Step 6: Repeat for `packages/store/`**

`packages/store/pubspec.yaml`:

```yaml
name: store
description: Cosmetic catalog, entitlements, and purchase flows for Amiro. Not yet implemented.
version: 0.1.0
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"
dev_dependencies:
  lints: ^4.0.0
```

`packages/store/lib/store.dart`:

```dart
// Not yet implemented. See README.md for the planned public interface.
```

`packages/store/README.md`:

```markdown
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
```

- [ ] **Step 7: Verify each stub package resolves**

Run: `cd packages/sharing && dart pub get && dart analyze`
Run: `cd packages/nfc && dart pub get && dart analyze`
Run: `cd packages/qr && dart pub get && dart analyze`
Run: `cd packages/store && dart pub get && dart analyze`
Expected: each succeeds with no issues.

- [ ] **Step 8: Commit**

```bash
git add packages/sharing packages/nfc packages/qr packages/store
git commit -m "chore: add sharing/nfc/qr/store stub packages to lock in boundaries"
```

---

## Task 8: `app/` shell — Riverpod wiring, providers, routing skeleton

**Files:**
- Create: `app/pubspec.yaml`
- Create: `app/lib/main.dart`
- Create: `app/lib/app.dart`
- Create: `app/lib/identity/identity_providers.dart`
- Create: `app/lib/avatar/avatar_providers.dart`
- Test: `app/test/identity/identity_providers_test.dart`

**Interfaces:**
- Consumes: `Identity`, `IdentityRepository`, `IsarIdentityRepository`, `openIdentityIsar` from Task 4; `AvatarDefinition` from Task 5; `AvatarRenderer`, `ThermionAvatarRenderer` from Task 6.
- Produces: `final identityRepositoryProvider = Provider<IdentityRepository>(...)`, `final currentIdentityProvider = AsyncNotifierProvider<CurrentIdentityNotifier, Identity?>(...)` with methods `Future<void> save(Identity identity)`, `final avatarRendererProvider = Provider<AvatarRenderer>(...)`.

- [ ] **Step 1: Create `app/pubspec.yaml`**

```yaml
name: amiro_app
description: Amiro — your digital identity, made wearable.
publish_to: none
version: 0.1.0
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  path_provider: ^2.1.4
  identity_core:
    path: ../packages/identity_core
  avatar_core:
    path: ../packages/avatar_core
  avatar_renderer:
    path: ../packages/avatar_renderer

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^4.0.0

flutter:
  uses-material-design: true
```

Also create `app/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml
```

- [ ] **Step 2: Write failing test — `app/test/identity/identity_providers_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/identity_providers.dart';

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? _stored;

  @override
  Future<Identity?> getCurrent() async => _stored;

  @override
  Future<void> save(Identity identity) async => _stored = identity;

  @override
  Future<void> clear() async => _stored = null;
}

void main() {
  test('currentIdentityProvider starts null then loads from repository', () async {
    final repo = _InMemoryIdentityRepository();
    await repo.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));

    final container = ProviderContainer(overrides: [
      identityRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final identity = await container.read(currentIdentityProvider.future);

    expect(identity!.displayName, 'Uday');
  });

  test('save persists through the repository and updates state', () async {
    final repo = _InMemoryIdentityRepository();
    final container = ProviderContainer(overrides: [
      identityRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    await container.read(currentIdentityProvider.future);
    await container.read(currentIdentityProvider.notifier).save(
          Identity(id: 'id-1', displayName: 'Uday', username: 'uday'),
        );

    final stored = await repo.getCurrent();
    expect(stored!.displayName, 'Uday');
    expect(container.read(currentIdentityProvider).value!.displayName, 'Uday');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd app && flutter pub get && flutter test test/identity/identity_providers_test.dart`
Expected: FAIL — `amiro_app/identity/identity_providers.dart` doesn't exist.

- [ ] **Step 4: Implement `app/lib/identity/identity_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

/// Overridden in `main.dart` with a real [IsarIdentityRepository] once
/// Isar is opened; overridden in tests with an in-memory fake.
final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  throw UnimplementedError('identityRepositoryProvider must be overridden');
});

class CurrentIdentityNotifier extends AsyncNotifier<Identity?> {
  @override
  Future<Identity?> build() {
    return ref.read(identityRepositoryProvider).getCurrent();
  }

  Future<void> save(Identity identity) async {
    await ref.read(identityRepositoryProvider).save(identity);
    state = AsyncData(identity);
  }
}

final currentIdentityProvider =
    AsyncNotifierProvider<CurrentIdentityNotifier, Identity?>(CurrentIdentityNotifier.new);
```

- [ ] **Step 5: Run tests to verify pass**

Run: `cd app && flutter test test/identity/identity_providers_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Implement `app/lib/avatar/avatar_providers.dart`** (no test — thin DI wiring, exercised via Task 10's screen test)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

/// Overridden in `main.dart` with a real [ThermionAvatarRenderer];
/// overridden in tests with a fake [AvatarRenderer].
final avatarRendererProvider = Provider<AvatarRenderer>((ref) {
  throw UnimplementedError('avatarRendererProvider must be overridden');
});
```

- [ ] **Step 7: Implement `app/lib/app.dart`**

```dart
import 'package:flutter/material.dart';

import 'identity/identity_edit_screen.dart';

class AmiroApp extends StatelessWidget {
  const AmiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amiro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const IdentityEditScreen(),
    );
  }
}
```

(`IdentityEditScreen` is created in Task 9 — this file is finished there; leave a `// TODO(Task 9): create IdentityEditScreen` marker is NOT acceptable per plan rules, so Task 8 ends by moving straight into Task 9 before committing `app.dart`. Combine the commit for Steps 1-7 with Task 9's work, OR — simpler — reorder: do Task 9 before writing `app.dart`. Reorder applied below.)

- [ ] **Step 8: Commit providers only (defer `app.dart` to end of Task 9)**

```bash
git add app/pubspec.yaml app/analysis_options.yaml app/lib/identity/identity_providers.dart app/lib/avatar/avatar_providers.dart app/test/identity/identity_providers_test.dart
git commit -m "feat(app): add Riverpod providers for identity and avatar renderer DI"
```

---

## Task 9: Identity create/edit screen

**Files:**
- Create: `app/lib/identity/identity_edit_screen.dart`
- Test: `app/test/identity/identity_edit_screen_test.dart`

**Interfaces:**
- Consumes: `currentIdentityProvider`, `identityRepositoryProvider` from Task 8; `Identity`, `PrivacyFlag` from Task 3.
- Produces: `class IdentityEditScreen extends ConsumerStatefulWidget` — used by `app.dart` (Task 8, finalized here) and by Task 10's avatar screen navigation.

- [ ] **Step 1: Write failing widget test — `app/test/identity/identity_edit_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

class _InMemoryIdentityRepository implements IdentityRepository {
  Identity? _stored;

  @override
  Future<Identity?> getCurrent() async => _stored;

  @override
  Future<void> save(Identity identity) async => _stored = identity;

  @override
  Future<void> clear() async => _stored = null;
}

void main() {
  testWidgets('entering a display name and saving persists it', (tester) async {
    final repo = _InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    final saved = await repo.getCurrent();
    expect(saved!.displayName, 'Uday');
    expect(saved.username, 'uday');
  });

  testWidgets('toggling a field private excludes it from publicFields', (tester) async {
    final repo = _InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [identityRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('displayNameField')), 'Uday');
    await tester.enterText(find.byKey(const Key('usernameField')), 'uday');
    await tester.enterText(find.byKey(const Key('emailField')), 'coffee.devloper@gmail.com');
    // Default is private; explicitly flip to public then back to private
    // to exercise the toggle path deterministically.
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('emailPrivacyToggle')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    final saved = await repo.getCurrent();
    expect(saved!.publicFields().containsKey('email'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/identity/identity_edit_screen_test.dart`
Expected: FAIL — `IdentityEditScreen` doesn't exist.

- [ ] **Step 3: Implement `app/lib/identity/identity_edit_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import 'identity_providers.dart';

class IdentityEditScreen extends ConsumerStatefulWidget {
  const IdentityEditScreen({super.key});

  @override
  ConsumerState<IdentityEditScreen> createState() => _IdentityEditScreenState();
}

class _IdentityEditScreenState extends ConsumerState<IdentityEditScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final Map<String, bool> _isPublic = {
    'bio': false,
    'email': false,
    'mobile': false,
    'xHandle': false,
    'instagramHandle': false,
    'website': false,
  };
  bool _hydrated = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _hydrateFromIdentity(Identity? identity) {
    if (_hydrated || identity == null) return;
    _hydrated = true;
    _displayNameController.text = identity.displayName;
    _usernameController.text = identity.username;
    _bioController.text = identity.bio ?? '';
    _emailController.text = identity.email ?? '';
    identity.privacy.forEach((key, flag) {
      if (_isPublic.containsKey(key)) {
        _isPublic[key] = flag.isPublic;
      }
    });
  }

  Future<void> _save() async {
    final existing = ref.read(currentIdentityProvider).value;
    final identity = Identity(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      displayName: _displayNameController.text,
      username: _usernameController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      avatarDefinitionId: existing?.avatarDefinitionId,
      privacy: _isPublic.map((key, value) => MapEntry(key, PrivacyFlag(value))),
    );
    await ref.read(currentIdentityProvider.notifier).save(identity);
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    _hydrateFromIdentity(identityAsync.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('displayNameField'),
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          TextField(
            key: const Key('usernameField'),
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            key: const Key('bioField'),
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('emailField'),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
              Switch(
                key: const Key('emailPrivacyToggle'),
                value: _isPublic['email']!,
                onChanged: (value) => setState(() => _isPublic['email'] = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('saveButton'),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify pass**

Run: `cd app && flutter test test/identity/identity_edit_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Finish `app/lib/app.dart` (deferred from Task 8) and `app/lib/main.dart`**

`app/lib/app.dart` (as written in Task 8 Step 7, now valid since `IdentityEditScreen` exists — write it now):

```dart
import 'package:flutter/material.dart';

import 'identity/identity_edit_screen.dart';

class AmiroApp extends StatelessWidget {
  const AmiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amiro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const IdentityEditScreen(),
    );
  }
}
```

`app/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:identity_core/identity_core.dart';

import 'app.dart';
import 'identity/identity_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final isar = await openIdentityIsar(directory: supportDir.path);
  final repository = IsarIdentityRepository(isar);

  runApp(
    ProviderScope(
      overrides: [identityRepositoryProvider.overrideWithValue(repository)],
      child: const AmiroApp(),
    ),
  );
}
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/app.dart app/lib/main.dart app/lib/identity/identity_edit_screen.dart app/test/identity/identity_edit_screen_test.dart
git commit -m "feat(app): add identity create/edit screen with privacy toggles"
```

---

## Task 10: Placeholder 3D assets + avatar screen with render/swap

**Files:**
- Create: `packages/avatar_renderer/assets/avatars/body_placeholder.glb`
- Create: `packages/avatar_renderer/assets/cosmetics/top_placeholder.glb`
- Create: `packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb`
- Modify: `packages/avatar_renderer/pubspec.yaml` (register assets)
- Create: `app/lib/avatar/avatar_screen.dart`
- Modify: `app/lib/app.dart` (add navigation to avatar screen)
- Test: `app/test/avatar/avatar_screen_test.dart`

**Interfaces:**
- Consumes: `AvatarRenderer`, `avatarRendererProvider` from Task 6/8; `AvatarDefinition` from Task 5; `currentIdentityProvider` from Task 8.
- Produces: `class AvatarScreen extends ConsumerStatefulWidget`.

- [ ] **Step 1: Generate placeholder GLB assets**

These are procedurally generated primitive meshes (a cube for the body, a smaller offset cube for "top", a thin flat box for "glasses") — not final art, per spec §7. Generate them with a short Python script using `pygltflib` (or, if unavailable, any equivalent minimal-glTF-writer approach) so the files are real valid GLBs, not empty placeholders:

```bash
pip install --quiet pygltflib
python3 - <<'EOF'
import pygltflib
import struct
import os

def make_box_glb(path, size=(1.0, 1.0, 1.0), color=(0.6, 0.6, 0.6, 1.0)):
    sx, sy, sz = size
    vertices = [
        (-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz),
        (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz),
    ]
    indices = [
        0,1,2, 2,3,0, 4,5,6, 6,7,4,
        0,1,5, 5,4,0, 2,3,7, 7,6,2,
        1,2,6, 6,5,1, 0,3,7, 7,4,0,
    ]

    vtx_bytes = b"".join(struct.pack("<fff", *v) for v in vertices)
    idx_bytes = b"".join(struct.pack("<H", i) for i in indices)
    if len(idx_bytes) % 4 != 0:
        idx_bytes += b"\x00\x00"
    blob = vtx_bytes + idx_bytes

    gltf = pygltflib.GLTF2(
        scene=0,
        scenes=[pygltflib.Scene(nodes=[0])],
        nodes=[pygltflib.Node(mesh=0)],
        meshes=[pygltflib.Mesh(primitives=[pygltflib.Primitive(
            attributes=pygltflib.Attributes(POSITION=0), indices=1, material=0,
        )])],
        materials=[pygltflib.Material(
            pbrMetallicRoughness=pygltflib.PbrMetallicRoughness(baseColorFactor=list(color)),
        )],
        accessors=[
            pygltflib.Accessor(bufferView=0, componentType=pygltflib.FLOAT, count=len(vertices),
                                type=pygltflib.VEC3,
                                max=[sx, sy, sz], min=[-sx, -sy, -sz]),
            pygltflib.Accessor(bufferView=1, componentType=pygltflib.UNSIGNED_SHORT,
                                count=len(indices), type=pygltflib.SCALAR),
        ],
        bufferViews=[
            pygltflib.BufferView(buffer=0, byteOffset=0, byteLength=len(vtx_bytes), target=pygltflib.ARRAY_BUFFER),
            pygltflib.BufferView(buffer=0, byteOffset=len(vtx_bytes), byteLength=len(idx_bytes), target=pygltflib.ELEMENT_ARRAY_BUFFER),
        ],
        buffers=[pygltflib.Buffer(byteLength=len(blob))],
    )
    gltf.set_binary_blob(blob)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    gltf.save_binary(path)

make_box_glb("packages/avatar_renderer/assets/avatars/body_placeholder.glb", size=(0.3, 0.8, 0.2), color=(0.7, 0.6, 0.5, 1.0))
make_box_glb("packages/avatar_renderer/assets/cosmetics/top_placeholder.glb", size=(0.35, 0.4, 0.25), color=(0.2, 0.3, 0.8, 1.0))
make_box_glb("packages/avatar_renderer/assets/cosmetics/glasses_placeholder.glb", size=(0.25, 0.05, 0.05), color=(0.1, 0.1, 0.1, 1.0))
EOF
```

- [ ] **Step 2: Register assets in `packages/avatar_renderer/pubspec.yaml`**

Add:

```yaml
flutter:
  assets:
    - assets/avatars/body_placeholder.glb
    - assets/cosmetics/top_placeholder.glb
    - assets/cosmetics/glasses_placeholder.glb
```

(`packages/avatar_renderer/pubspec.yaml` had no `flutter:` block before this — add it as a new top-level key.)

- [ ] **Step 3: Write failing widget test — `app/test/avatar/avatar_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/avatar/avatar_screen.dart';

class _FakeAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;
  final List<String> calls = [];

  @override
  AvatarDefinition? get current => _current;

  @override
  Future<void> load(AvatarDefinition definition) async {
    calls.add('load:${definition.id}');
    _current = definition;
  }

  @override
  Widget buildView() => const ColoredBox(color: Colors.grey, child: SizedBox(height: 200));

  @override
  Future<void> updateSlot(String slot, String? assetId) async {
    calls.add('updateSlot:$slot:$assetId');
    _current = _current!.copyWithSlot(slot, assetId);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('avatar screen loads the definition on start and renders a view', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('load:default'));
    expect(find.byType(ColoredBox), findsOneWidget);
  });

  testWidgets('tapping the glasses toggle swaps that slot', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.calls, contains('updateSlot:glasses:glasses_placeholder'));
    expect(renderer.current!.glasses, 'glasses_placeholder');
  });

  testWidgets('tapping again removes the glasses', (tester) async {
    final renderer = _FakeAvatarRenderer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [avatarRendererProvider.overrideWithValue(renderer)],
        child: const MaterialApp(home: AvatarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleGlassesButton')));
    await tester.pumpAndSettle();

    expect(renderer.current!.glasses, isNull);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd app && flutter test test/avatar/avatar_screen_test.dart`
Expected: FAIL — `AvatarScreen` doesn't exist.

- [ ] **Step 5: Implement `app/lib/avatar/avatar_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';

import 'avatar_providers.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  bool _loaded = false;
  bool _glassesOn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_placeholder',
        top: 'top_placeholder',
      );
      ref.read(avatarRendererProvider).load(definition).then((_) => setState(() {}));
    }
  }

  Future<void> _toggleGlasses() async {
    final renderer = ref.read(avatarRendererProvider);
    final next = !_glassesOn;
    await renderer.updateSlot('glasses', next ? 'glasses_placeholder' : null);
    setState(() => _glassesOn = next);
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Avatar')),
      body: Column(
        children: [
          Expanded(child: renderer.buildView()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('toggleGlassesButton'),
              onPressed: _toggleGlasses,
              child: Text(_glassesOn ? 'Remove glasses' : 'Add glasses'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify pass**

Run: `cd app && flutter test test/avatar/avatar_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Wire navigation in `app/lib/app.dart`**

```dart
import 'package:flutter/material.dart';

import 'identity/identity_edit_screen.dart';
import 'avatar/avatar_screen.dart';

class AmiroApp extends StatelessWidget {
  const AmiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amiro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const _RootTabs(),
    );
  }
}

class _RootTabs extends StatefulWidget {
  const _RootTabs();

  @override
  State<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<_RootTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [IdentityEditScreen(), AvatarScreen()];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Identity'),
          NavigationDestination(icon: Icon(Icons.face_retouching_natural), label: 'Avatar'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Wire the real renderer in `app/lib/main.dart`**

Add to `main.dart`, alongside the existing `identityRepositoryProvider` override:

```dart
import 'package:avatar_renderer/avatar_renderer.dart';
import 'avatar/avatar_providers.dart';
```

And inside `runApp`'s `overrides` list, add:

```dart
avatarRendererProvider.overrideWithValue(
  ThermionAvatarRenderer(surface: ThermionFilamentSurface(/* see Step 9 */)),
),
```

- [ ] **Step 9: Resolve the `ThermionFilamentSurface` construction argument**

`ThermionFilamentSurface` (Task 6) wraps a `thermion.ThermionViewer`. Check `thermion_flutter`'s actual initialization API (its README/example on pub.dev — this is exactly the kind of detail that may have shifted since this plan was written against v0.5.0's package metadata) for how a `ThermionViewer` instance is obtained (commonly either constructed directly, or obtained from a controller tied to the `ThermionWidget`). Adjust `ThermionFilamentSurface`'s constructor and `main.dart`'s wiring to match the real initialization sequence. This is the one integration point in the whole plan with unavoidable exposure to an external package's exact API shape — isolated here per the interface boundary in Task 6.

- [ ] **Step 10: Run full app test suite**

Run: `cd app && flutter test`
Expected: all tests PASS.

- [ ] **Step 11: Commit**

```bash
git add packages/avatar_renderer/assets packages/avatar_renderer/pubspec.yaml app/lib/avatar/avatar_screen.dart app/lib/app.dart app/lib/main.dart app/test/avatar/avatar_screen_test.dart
git commit -m "feat(app): add avatar screen with render/swap wired to Thermion renderer"
```

---

## Task 11: Seed `docs/` tree from the PRD

**Files:**
- Create: `docs/product/requirements.md`
- Create: `docs/architecture/overview.md`
- Create: `docs/protocols/identity-link.md`
- Create: `docs/protocols/avatar-format.md`
- Create: `docs/legal/asset-policy.md`
- Create: `docs/legal/third-party-licenses.md`
- Create: `docs/qa/test-plan.md`

**Interfaces:**
- Produces: docs matching the structure the spec's §3 repository layout committed to.

- [ ] **Step 1: Create `docs/product/requirements.md`**

Paste the full PRD text the user provided (both the original "Digital Identity Avatar App v1" draft and the "Amiro" revision), verbatim, under two clearly separated headings (`## Original draft`, `## Amiro revision`), with a one-line preface noting the Amiro revision supersedes the original where they conflict (per the user's stated correction about unverified critique claims).

- [ ] **Step 2: Create `docs/architecture/overview.md`**

Copy the full content of `docs/superpowers/specs/2026-09-22-amiro-foundation-design.md` (Task from brainstorming) as the initial architecture overview, with a preface line: "This is the living architecture doc; the original design rationale is preserved at `../superpowers/specs/2026-09-22-amiro-foundation-design.md`."

- [ ] **Step 3: Create `docs/protocols/avatar-format.md`**

```markdown
# Avatar Definition Format

`AvatarDefinition` (see `packages/avatar_core/lib/src/avatar_definition.dart`)
is the platform-independent avatar identity. Same definition renders
identically on Android and iOS via `packages/avatar_renderer`.

## Schema

```json
{
  "id": "string, required, unique per avatar",
  "body": "string | null — asset id, e.g. body_001",
  "face": "string | null",
  "skin": "string | null",
  "hair": "string | null",
  "eyes": "string | null",
  "eyebrows": "string | null",
  "facialHair": "string | null",
  "top": "string | null",
  "bottom": "string | null",
  "shoes": "string | null",
  "glasses": "string | null",
  "earrings": "string | null",
  "necklace": "string | null",
  "goldChain": "string | null",
  "watch": "string | null",
  "hat": "string | null",
  "background": "string | null",
  "effects": "string | null"
}
```

## Asset resolution

An asset id resolves to a packaged glTF/GLB file via
`packages/avatar_renderer/lib/src/avatar_asset_resolver.dart`:
`body` slot → `assets/avatars/<id>.glb`; every other slot →
`assets/cosmetics/<id>.glb`.

## Current status (as of the foundation pass)

Only `body`, `top`, `glasses` are populated with real (placeholder)
assets. The remaining 15 slots are defined in the schema but have no
shipped assets yet — that's Agent 6/Asset Content's future work.
```

- [ ] **Step 4: Create `docs/protocols/identity-link.md`**

```markdown
# Identity Link Protocol

**Status: not started.** Planned for milestone M4 (Sharing), owned by
the NFC/Sharing agent.

Planned shape (from the PRD): a compact identity URL,
`https://id.amiro.app/u/<id>`, used identically as the NFC payload and
the QR code content. The receiver's app (if installed) resolves it via
Universal Link / App Link to the native profile; otherwise it opens
the web fallback. NFC/QR never carry the full profile — only this
identifier.

See `packages/sharing/README.md`, `packages/nfc/README.md`,
`packages/qr/README.md` for the per-package planned interfaces.
```

- [ ] **Step 5: Create `docs/legal/asset-policy.md`**

```markdown
# Asset Policy

**Status: stub — full policy not yet written.** Owned by the Legal/IP/
App Store agent.

Binding rules already established:

- No Bitmoji/Snapchat assets, characters, animations, textures, or UI
  patterns — inspiration only, never copying.
- No unlicensed luxury brands, logos, or celebrity likenesses.
- All shipped cosmetic/avatar assets must be original, properly
  licensed, and commercially usable, tracked in
  `assets/LICENSES.md` and `assets/ATTRIBUTIONS.md` (not yet created —
  create alongside the first real asset drop).

**Current exception, tracked here on purpose:** the 3 placeholder
meshes shipped in this foundation pass
(`packages/avatar_renderer/assets/avatars/body_placeholder.glb`,
`.../cosmetics/top_placeholder.glb`, `.../cosmetics/glasses_placeholder.glb`)
are procedurally generated primitive boxes with no third-party origin —
compliant by construction, but explicitly temporary and not
representative of final art style.
```

- [ ] **Step 6: Create `docs/legal/third-party-licenses.md`**

```markdown
# Third-Party Licenses

Tracks license terms for third-party packages/engines this project
depends on. Update whenever a new significant dependency is added.

| Dependency | Version (as of this pass) | License | Notes |
|---|---|---|---|
| thermion_flutter | 0.5.0 | Check package source (pub.dev listing at time of writing did not surface a top-level SPDX id via the API — verify against the repo's LICENSE file before any public release) | 3D rendering engine (Filament wrapper) |
| Isar | ^3.1.8 | Apache-2.0 | Local storage |
| Melos | ^8.9.0 (dev-only) | MIT | Monorepo tooling, not shipped in the app |
| Riverpod (flutter_riverpod) | ^2.5.1 | MIT | State management |
```

- [ ] **Step 7: Create `docs/qa/test-plan.md`**

```markdown
# QA Test Plan

**Status: this pass covers unit/widget tests only (see below). Full
device-matrix QA (Android phone, iPhone, Android+NFC, iPhone+NFC) is
out of scope until NFC/QR ship in M4.**

## Coverage shipped in this pass

- `rust/core`: `cargo test` — Identity struct validation + serde round-trip.
- `packages/identity_core`: unit tests for `Identity` model, JSON
  round-trip, `publicFields()` privacy filtering, `IsarIdentityRepository`
  CRUD.
- `packages/avatar_core`: unit tests for `AvatarDefinition`, slot
  update, JSON round-trip.
- `packages/avatar_renderer`: unit tests for asset path resolution and
  `ThermionAvatarRenderer` slot-swap bookkeeping (engine calls faked).
- `app`: widget tests for identity create/edit (field entry, privacy
  toggle, save) and avatar screen (initial load, cosmetic swap on/off).

## Explicitly not covered yet

NFC, QR, deep links, purchases, offline/online sync divergence, profile
privacy on the (not-yet-built) web fallback, app-not-installed
experience, cross-device pairing. Each becomes a QA Agent task when its
owning milestone ships.
```

- [ ] **Step 8: Commit**

```bash
git add docs
git commit -m "docs: seed product/architecture/protocol/legal/qa docs from PRD and design spec"
```

---

## Task 12: Final CI green-up, repo push (with explicit confirmation)

**Files:**
- No new files — verification and publish step only.

- [ ] **Step 1: Run the full workspace check locally**

```bash
melos bootstrap
melos run analyze
melos run test
(cd rust/core && cargo test && cargo clippy -- -D warnings)
```

Expected: all green. Fix any failures surfaced only when packages are
resolved together (cross-package version conflicts, etc.) before
proceeding — do not push red CI.

- [ ] **Step 2: Ask the user for explicit confirmation before creating the public GitHub repo and pushing**

This is a publish action (creating `DevelopersCoffee/amiro` as a public
repo, pushing the initial history) — per the plan's Global Constraints,
confirm with the user in chat before running:

```bash
gh repo create DevelopersCoffee/amiro --public --source=. --remote=origin
git push -u origin main
```

- [ ] **Step 3: Verify CI runs green on the pushed commit**

Check the Actions run for the initial push (`gh run list --repo DevelopersCoffee/amiro --limit 1`, then `gh run watch <id> --repo DevelopersCoffee/amiro`). Fix and push a follow-up commit if anything fails in the GitHub-hosted environment that didn't reproduce locally (e.g. a Flutter/Rust toolchain version mismatch).

---

## Self-Review Notes

**Spec coverage:** §3 repo layout → Tasks 1, 7 (stubs), 11 (docs). §4 package contracts → Tasks 3-6. §5 tech choices → reflected in every package's pubspec (Riverpod, Isar, Melos, flutter_rust_bridge *not* wired this pass — flagged explicitly in Task 3 as deferred since M1 doesn't need the Dart↔Rust bridge yet, only `cargo test`-level validation of the Rust struct). §6 data flow → Tasks 9, 10. §7 risks → carried into `docs/legal/asset-policy.md` (Task 11) and the `thermion_flutter` API-shape note (Task 6 Step 11, Task 10 Step 9). §8 testing plan → one test task per package plus the CI task (Task 1, finalized Task 12). §9 milestone mapping → this plan's scope matches exactly (M0 + M1 + thin M2 slice).

**Note on flutter_rust_bridge:** the spec's §4 describes a bridged Rust `Identity` struct, but this plan does not wire the bridge — Rust core ships and is tested standalone (`cargo test`), while the app's actual Identity persistence uses the pure-Dart `identity_core` package. Wiring `flutter_rust_bridge` is deferred: it's a real build-tooling addition (codegen step, native build changes on both platforms) that this pass's identity logic doesn't need to function, and forcing it in now risks exactly the kind of premature-complexity the spec's YAGNI framing (§1, "basic... end-to-end pipeline") argues against. Flagged here rather than silently dropped so it isn't mistaken for an oversight.
