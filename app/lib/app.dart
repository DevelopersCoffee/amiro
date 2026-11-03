import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

import 'identity/identity_edit_screen.dart';
import 'avatar/avatar_screen.dart';
import 'avatar/avatar_providers.dart';
import 'avatar/avatar_identity_sync.dart';
import 'avatar/persistent_thermion_overlay.dart';
import 'branding/dc_splash.dart';
import 'discovery/passport_screen.dart';
import 'sharing/incoming_share_listener.dart';
import 'sharing/share_screen.dart';
import 'store/store_screen.dart';
import 'theme/amiro_theme.dart';

class AmiroApp extends StatelessWidget {
  const AmiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amiro',
      theme: buildAmiroTheme(),
      home: const _SplashGate(),
    );
  }
}

/// Shows the Developers Coffee sting first; the tabs (and the native avatar
/// overlay) mount only after it ends so nothing native renders under it.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  var _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (_splashDone) {
      return const IncomingShareListener(child: AmiroRootTabs());
    }
    return DcSplash(onDone: () => setState(() => _splashDone = true));
  }
}

/// Store tab activity for a given bottom-nav index (used by [AmiroRootTabs]).
@visibleForTesting
Widget amiroRootTabStoreScreenForIndex(int index) {
  // Keep [StoreScreen] out of the tree until the Store tab is selected (R3/R3b).
  if (index != 2) return const SizedBox.shrink();
  return const StoreScreen(isActive: true);
}

/// Root tab shell (Identity, Avatar, Store, Share, Passport). Used at launch
/// after the splash; exposed for tests that verify tab wiring (R3).
class AmiroRootTabs extends ConsumerStatefulWidget {
  const AmiroRootTabs({
    super.key,
    @visibleForTesting this.omitThermionOverlayForTest = false,
    @visibleForTesting this.lightweightTabsForTest = false,
  });

  /// Skips [PersistentThermionOverlay] in widget tests (same tab wiring).
  @visibleForTesting
  final bool omitThermionOverlayForTest;

  /// Replaces heavy tabs with placeholders; keeps [StoreScreen] wiring for R3.
  @visibleForTesting
  final bool lightweightTabsForTest;

  @override
  ConsumerState<AmiroRootTabs> createState() => _AmiroRootTabsState();
}

class _AmiroRootTabsState extends ConsumerState<AmiroRootTabs> {
  int _index = 0;
  var _registeredThermionGate = false;

  void _registerThermionGateOnce() {
    if (_registeredThermionGate) return;
    _registeredThermionGate = true;
    ThermionViewDetachGate.beforeEngineMutation = () async {
      await ref.read(avatarRendererProvider).pausePresentation();
    };
  }

  void _onTabSelected(int nextIndex) {
    if (nextIndex == _index) return;
    setState(() => _index = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.omitThermionOverlayForTest) {
      _registerThermionGateOnce();
    }
    final screens = widget.lightweightTabsForTest
        ? [
            const SizedBox.shrink(),
            const SizedBox.shrink(),
            amiroRootTabStoreScreenForIndex(_index),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
          ]
        : [
            const IdentityEditScreen(),
            const AvatarScreen(),
            amiroRootTabStoreScreenForIndex(_index),
            const ShareScreen(),
            const PassportScreen(),
          ];
    final body = Stack(
      fit: StackFit.expand,
      children: [
        IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: screens,
        ),
        if (!widget.omitThermionOverlayForTest)
          PersistentThermionOverlay(activeTabIndex: _index),
      ],
    );
    return Scaffold(
      body: widget.lightweightTabsForTest
          ? body
          : AvatarIdentitySyncListener(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Identity',
          ),
          NavigationDestination(
            icon: Icon(Icons.face_outlined),
            selectedIcon: Icon(Icons.face_retouching_natural),
            label: 'Avatar',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.ios_share_outlined),
            selectedIcon: Icon(Icons.ios_share),
            label: 'Share',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Passport',
          ),
        ],
      ),
    );
  }
}
