import 'package:flutter/material.dart';

import 'identity/identity_edit_screen.dart';
import 'avatar/avatar_screen.dart';
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

class _RootTabs extends StatefulWidget {
  const _RootTabs();

  @override
  State<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<_RootTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
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
        onDestinationSelected: (i) => setState(() => _index = i),
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
