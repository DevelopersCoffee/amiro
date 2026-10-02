import 'dart:convert';

import 'package:avatar_core/avatar_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';

import '../avatar/avatar_defaults.dart';
import '../theme/amiro_card.dart';
import '../theme/amiro_theme.dart';
import '../theme/section_label.dart';
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
  AvatarGender _avatarGender = AvatarGender.male;
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
    _avatarGender = resolveAvatarGender(identity);
    identity.privacy.forEach((key, flag) {
      if (_isPublic.containsKey(key)) {
        _isPublic[key] = flag.isPublic;
      }
    });
  }

  String? _avatarJsonWithGenderBody(Identity? existing) {
    final raw = existing?.avatarDefinitionJson;
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final def = AvatarDefinition.fromJson(map);
    final bodyId = defaultBodyAssetId(_avatarGender);
    if (!isBodyAssetAvailable(bodyId)) {
      return raw;
    }
    if (def.body == bodyId) return raw;
    return jsonEncode(def.copyWithSlot('body', bodyId).toJson());
  }

  Future<void> _save() async {
    final existing = ref.read(currentIdentityProvider).value;
    final identity = Identity(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      displayName: _displayNameController.text,
      username: _usernameController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      avatarGender: _avatarGender.wireName,
      avatarDefinitionJson: _avatarJsonWithGenderBody(existing) ??
          existing?.avatarDefinitionJson,
      privacy: _isPublic.map((key, value) => MapEntry(key, PrivacyFlag(value))),
    );
    await ref.read(currentIdentityProvider.notifier).save(identity);
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    _hydrateFromIdentity(identityAsync.value);

    final femaleBodyPending = _avatarGender == AvatarGender.female &&
        !isBodyAssetAvailable(defaultBodyAssetId(AvatarGender.female));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Amiro')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AmiroSpacing.md,
          AmiroSpacing.md,
          AmiroSpacing.md,
          // Root [NavigationBar] + Save must stay reachable when the female
          // “coming soon” note is visible.
          AmiroSpacing.md + MediaQuery.paddingOf(context).bottom + 72,
        ),
        children: [
          AmiroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('AVATAR'),
                const SizedBox(height: AmiroSpacing.sm),
                Text(
                  'Which avatar do you want to develop?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AmiroSpacing.md),
                SegmentedButton<AvatarGender>(
                  key: const Key('avatarGenderSelector'),
                  segments: const [
                    ButtonSegment(
                      value: AvatarGender.male,
                      label: Text('Male'),
                      icon: Icon(Icons.man_outlined),
                    ),
                    ButtonSegment(
                      value: AvatarGender.female,
                      label: Text('Female'),
                      icon: Icon(Icons.woman_outlined),
                    ),
                  ],
                  selected: {_avatarGender},
                  onSelectionChanged: (selected) {
                    setState(() => _avatarGender = selected.first);
                  },
                ),
                if (femaleBodyPending) ...[
                  const SizedBox(height: AmiroSpacing.sm),
                  Text(
                    'Female body assets are not shipped in this build yet. '
                    'Your choice is saved; Avatar preview unlocks when '
                    'body_superhero_female.glb lands.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AmiroColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AmiroSpacing.md),
          AmiroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('PROFILE'),
                const SizedBox(height: AmiroSpacing.md),
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
              ],
            ),
          ),
          const SizedBox(height: AmiroSpacing.md),
          AmiroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('CONTACT'),
                const SizedBox(height: AmiroSpacing.md),
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
                      onTap: () => setState(
                        () =>
                            _isPublic['email'] = !(_isPublic['email'] ?? false),
                      ),
                      child: Switch(
                        value: _isPublic['email']!,
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AmiroSpacing.lg),
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
