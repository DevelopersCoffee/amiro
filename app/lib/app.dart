import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

import 'identity/identity_edit_screen.dart';
import 'avatar/avatar_screen.dart';
import 'avatar/avatar_thermion_attach.dart';
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
      home: const IncomingShareListener(child: _RootTabs()),
    );
  }
}

class _RootTabs extends ConsumerStatefulWidget {
  const _RootTabs();

  @override
  ConsumerState<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends ConsumerState<_RootTabs> {
  int _index = 0;
  var _tabSwitchEpoch = 0;

  var _registeredThermionGate = false;

  void _registerThermionGateOnce() {
    if (_registeredThermionGate) return;
    _registeredThermionGate = true;
    ThermionViewDetachGate.beforeEngineMutation = () async {
      await ref
          .read(avatarThermionAttachedProvider.notifier)
          .detachForEngineMutation();
    };
  }

  Future<void> _onTabSelected(int nextIndex) async {
    if (nextIndex == _index) return;
    final epoch = ++_tabSwitchEpoch;
    final previous = _index;
    const thermionTabs = {1, 2};
    if (thermionTabs.contains(previous) || thermionTabs.contains(nextIndex)) {
      await ref
          .read(avatarThermionAttachedProvider.notifier)
          .detachForEngineMutation();
    }
    if (!mounted || epoch != _tabSwitchEpoch) return;
    setState(() => _index = nextIndex);
    if (thermionTabs.contains(nextIndex)) {
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || epoch != _tabSwitchEpoch) return;
      ref.read(avatarThermionAttachedProvider.notifier).attach();
    }
  }

  @override
  Widget build(BuildContext context) {
    _registerThermionGateOnce();
    const screens = [
      IdentityEditScreen(),
      AvatarScreen(),
      StoreScreen(),
      ShareScreen(),
      PassportScreen(),
    ];
    return Scaffold(
      body: screens[_index],
      // Outline-vs-filled icon pairs make the active tab clear without
      // depending on colour alone (DESIGN.md: brass is reserved for
      // equipped/price/primary-action, not a 4th "nav accent" use).
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => unawaited(_onTabSelected(i)),
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
