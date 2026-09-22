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
