# Third-Party Licenses

Tracks license terms for third-party packages/engines this project
depends on. Update whenever a new significant dependency is added.

| Dependency | Version (as of this pass) | License | Notes |
|---|---|---|---|
| thermion_flutter | 0.5.0 | Check package source (pub.dev listing at time of writing did not surface a top-level SPDX id via the API — verify against the repo's LICENSE file before any public release) | 3D rendering engine (Filament wrapper) |
| Isar | ^3.1.0+1 | Apache-2.0 | Local storage |
| isar_flutter_libs | ^3.1.0+1 | Apache-2.0 | Bundled Isar native binaries; the only way the shipped app gets Isar Core (production code never downloads it) |
| path_provider | ^2.1.4 | BSD-3-Clause | Resolves the on-device directory the Isar database lives in |
| Melos | ^8.9.0 (dev-only) | MIT | Monorepo tooling, not shipped in the app |
| Riverpod (flutter_riverpod) | ^2.5.1 | MIT | State management |
| lints | ^4.0.0 (dev-only) | BSD-3-Clause | Analyzer rule set, not shipped in the app |
| cli_util | ^0.6.0 (override, dev-only) | BSD-3-Clause | Workspace-root `dependency_overrides` entry needed to reconcile Melos with thermion's transitive constraint; see the root `pubspec.yaml` |
