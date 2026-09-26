import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';

import '../avatar/avatar_providers.dart';
import '../identity/identity_providers.dart';
import '../sharing/own_encounter.dart';
import '../sharing/remote_avatar_view.dart';
import '../store/store_providers.dart';
import '../theme/amiro_theme.dart';
import 'date_format.dart';
import 'discovery_providers.dart';
import 'encounter_comparison.dart';

/// Shown when a valid encounter card is scanned or tapped: their avatar and
/// card against yours, and an explicit "Save to passport".
///
/// Receiving writes nothing. The passport (and the repeat count of someone
/// already in it) changes only when the user saves; leaving the screen
/// without saving leaves everything as it was.
///
/// Only their avatar is rendered in 3D. Yours is summarised as text: a
/// second live 3D view next to the theirs is a device-only risk that hasn't
/// been verified, and the card is about what they are wearing.
class EncounterScreen extends ConsumerStatefulWidget {
  final EncounterQr encounter;

  const EncounterScreen({super.key, required this.encounter});

  @override
  ConsumerState<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends ConsumerState<EncounterScreen> {
  late final Future<EncounterResult> _result;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _result = _receive();
  }

  Future<EncounterResult> _receive() async {
    // The processor needs the user's own identity id to recognise their own
    // card; on a cold start (a deep link) it may not have loaded yet.
    await ref.read(currentIdentityProvider.future);
    return ref
        .read(encounterProcessorProvider)
        .receivePayload(widget.encounter.payload);
  }

  Future<void> _save(PendingEncounter pending) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(encounterProcessorProvider).save(pending);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't save to your passport")),
      );
      return;
    }
    ref.invalidate(encounterRecordsProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Saved to your passport')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encounter')),
      body: FutureBuilder<EncounterResult>(
        future: _result,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) {
            return snapshot.hasError
                ? const _Message("This card couldn't be read.")
                : const Center(child: CircularProgressIndicator());
          }
          return switch (result) {
            SelfEncounter() => const _Message("That's your own Amiro."),
            EncounterRejected(:final error) => _Message(
              "This card couldn't be read: ${error.message}",
            ),
            PendingEncounter() => _content(context, result),
          };
        },
      ),
    );
  }

  Widget _content(BuildContext context, PendingEncounter pending) {
    final theirs = widget.encounter.payload;
    final contact = widget.encounter.contact;
    final identity = ref.watch(currentIdentityProvider).value;
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const <String>{};
    final mine = identity == null
        ? null
        : buildOwnEncounterPayload(
            identity: identity,
            definition: ref.watch(avatarRendererProvider).current,
            purchasedIds: owned,
          );
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.labelSmall?.copyWith(
      color: AmiroColors.textMuted,
      letterSpacing: 2.4,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        switch (pending) {
          NewEncounter() => Text('NEW AMIRO', style: label),
          KnownEncounter(:final previous) => Row(
            children: [
              Text('MET BEFORE', style: label),
              const SizedBox(width: 8),
              Text(
                '${previous.encounterCount}\u00d7 \u00b7 first ${formatShortDate(previous.firstEncountered)}',
                style: amiroMono(
                  context,
                ).copyWith(color: AmiroColors.textMuted),
              ),
            ],
          ),
        },
        const SizedBox(height: 12),
        RemoteAvatarView(avatarConfigJson: theirs.activeAvatarConfig),
        const SizedBox(height: 16),
        Text(theirs.displayName, style: textTheme.headlineSmall),
        if (contact?.username != null) Text('@${contact!.username}'),
        if (contact?.bio != null) ...[
          const SizedBox(height: 8),
          Text(contact!.bio!),
        ],
        const SizedBox(height: 24),
        EncounterComparison(mine: mine, theirs: theirs),
        if (contact != null && _hasContactDetails(contact)) ...[
          const SizedBox(height: 24),
          Text('CONTACT', style: label),
          const SizedBox(height: 8),
          if (contact.email != null) Text('Email: ${contact.email}'),
          if (contact.mobile != null) Text('Mobile: ${contact.mobile}'),
          if (contact.xHandle != null) Text('X: ${contact.xHandle}'),
          if (contact.instagramHandle != null)
            Text('Instagram: ${contact.instagramHandle}'),
          if (contact.website != null) Text('Website: ${contact.website}'),
        ],
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('saveToPassportButton'),
          onPressed: _saving ? null : () => _save(pending),
          child: Text(
            pending is NewEncounter ? 'Save to passport' : 'Update passport',
          ),
        ),
      ],
    );
  }

  bool _hasContactDetails(ContactCard c) =>
      c.email != null ||
      c.mobile != null ||
      c.xHandle != null ||
      c.instagramHandle != null ||
      c.website != null;
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
