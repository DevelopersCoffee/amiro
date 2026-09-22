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
