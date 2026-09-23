import 'package:flutter/material.dart';

import 'identity/identity_edit_screen.dart';
import 'avatar/avatar_screen.dart';
import 'sharing/incoming_share_listener.dart';
import 'sharing/share_screen.dart';
import 'store/store_screen.dart';

class AmiroApp extends StatelessWidget {
  const AmiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amiro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
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
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Identity'),
          NavigationDestination(icon: Icon(Icons.face_retouching_natural), label: 'Avatar'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.ios_share), label: 'Share'),
        ],
      ),
    );
  }
}
