import 'dart:async';
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
  final _restoreController = TextEditingController();
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
  bool _userEdited = false;
  bool _applying = false;
  Timer? _saveTimer;
  Future<void> _saveQueue = Future<void>.value();
  String? _status;
  String? _recoveryCode;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _displayNameController,
      _usernameController,
      _bioController,
      _emailController,
    ]) {
      controller.addListener(_onEdited);
    }
    if (ref.read(profileCloudProvider).supportsRestore) {
      ref.read(profileCloudProvider).recoveryCode().then((code) {
        if (!mounted || code == null || code.isEmpty) return;
        setState(() => _recoveryCode = code);
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _restoreController.dispose();
    super.dispose();
  }

  bool get _hasProfileText =>
      _displayNameController.text.trim().isNotEmpty ||
      _usernameController.text.trim().isNotEmpty ||
      _bioController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty;

  void _onEdited() {
    if (_applying) return;
    _userEdited = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  void _hydrateFromIdentity(Identity? identity) {
    if (_hydrated || _userEdited || identity == null) return;
    _hydrated = true;
    _applying = true;
    _displayNameController.text = identity.displayName;
    _usernameController.text = identity.username;
    _bioController.text = identity.bio ?? '';
    _emailController.text = identity.email ?? '';
    _applying = false;
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

  Future<void> _save({bool announce = false}) {
    _saveTimer?.cancel();
    final run = _saveQueue.then((_) => _write(announce: announce));
    _saveQueue = run.catchError((Object _) {});
    return run;
  }

  Future<void> _write({required bool announce}) async {
    final existing = ref.read(currentIdentityProvider).value;
    if (!announce && !_hasProfileText && existing == null) return;

    final identity = Identity(
      id: existing?.id ?? newIdentityId(),
      displayName: _displayNameController.text,
      username: _usernameController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      avatarGender: _avatarGender.wireName,
      avatarDefinitionJson:
          _avatarJsonWithGenderBody(existing) ?? existing?.avatarDefinitionJson,
      privacy: _isPublic.map((key, value) => MapEntry(key, PrivacyFlag(value))),
    );
    await ref.read(currentIdentityProvider.notifier).save(identity);
    final remote = await ref.read(profileCloudProvider).push(identity);
    if (!mounted) return;
    if (remote) {
      final code = await ref.read(profileCloudProvider).recoveryCode();
      if (!mounted) return;
      setState(() {
        _recoveryCode = code ?? _recoveryCode;
        _status = 'Saved on this phone and backed up';
      });
    } else {
      setState(() => _status = 'Saved on this phone');
    }
    if (announce && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_status!)),
      );
    }
  }

  Future<void> _claim() async {
    final identity = await ref
        .read(profileCloudProvider)
        .claim(_restoreController.text);
    if (!mounted) return;
    if (identity == null) {
      setState(() => _status = 'That code did not match an Amiro');
      return;
    }
    await ref.read(currentIdentityProvider.notifier).save(identity);
    if (!mounted) return;
    _userEdited = false;
    _hydrated = false;
    setState(() {
      _hydrateFromIdentity(identity);
      _recoveryCode = _restoreController.text.trim();
      _status = 'Restored on this phone';
    });
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(currentIdentityProvider);
    _hydrateFromIdentity(identityAsync.value);
    final cloud = ref.watch(profileCloudProvider);

    final femaleBodyPending =
        _avatarGender == AvatarGender.female &&
        !isBodyAssetAvailable(defaultBodyAssetId(AvatarGender.female));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Amiro')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AmiroSpacing.md,
          AmiroSpacing.md,
          AmiroSpacing.md,
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
                    _onEdited();
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
                      onTap: () {
                        setState(
                          () => _isPublic['email'] =
                              !(_isPublic['email'] ?? false),
                        );
                        _onEdited();
                      },
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
            onPressed: () => _save(announce: true),
            child: const Text('Save'),
          ),
          if (_status != null) ...[
            const SizedBox(height: AmiroSpacing.sm),
            Text(
              _status!,
              key: const Key('identitySaveStatus'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AmiroColors.textMuted,
              ),
            ),
          ],
          if (cloud.supportsRestore) ...[
            const SizedBox(height: AmiroSpacing.md),
            AmiroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('ANOTHER DEVICE'),
                  const SizedBox(height: AmiroSpacing.sm),
                  Text(
                    'Items you bought stay with the Google account that paid. '
                    'On the other phone, open Store and tap Restore purchases.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AmiroSpacing.sm),
                  Text(
                    'Your name and avatar move with this code.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_recoveryCode != null) ...[
                    const SizedBox(height: AmiroSpacing.sm),
                    SelectableText(
                      _recoveryCode!,
                      key: const Key('recoveryCode'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: AmiroSpacing.md),
                  TextField(
                    key: const Key('restoreCodeField'),
                    controller: _restoreController,
                    decoration: const InputDecoration(
                      labelText: 'Code from your other phone',
                    ),
                  ),
                  const SizedBox(height: AmiroSpacing.sm),
                  OutlinedButton(
                    key: const Key('restoreCodeButton'),
                    onPressed: _claim,
                    child: const Text('Restore with code'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
