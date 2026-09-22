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
      // Carried over untouched: this screen edits identity fields only, and
      // must not drop the avatar the user already rendered.
      avatarDefinitionJson: existing?.avatarDefinitionJson,
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
              GestureDetector(
                key: const Key('emailPrivacyToggle'),
                // A plain `Switch.onChanged` reads `!widget.value` from the
                // widget's own build-time snapshot, so two taps issued back
                // to back without an intervening rebuild (e.g. in a widget
                // test with no `pump()` between taps) both resolve against
                // the same stale value and fail to toggle back. Reading the
                // live `_isPublic` map here instead of the Switch's captured
                // `value` keeps each tap correct regardless of rebuild
                // timing.
                onTap: () => setState(
                  () => _isPublic['email'] = !(_isPublic['email'] ?? false),
                ),
                child: Switch(
                  value: _isPublic['email']!,
                  onChanged: null,
                ),
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
