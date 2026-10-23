import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/strings.dart';
import '../data/cloud_sync.dart';
import '../../family/data/family_repository.dart';

class CloudPanel extends ConsumerStatefulWidget {
  const CloudPanel({super.key});
  @override
  ConsumerState<CloudPanel> createState() => _CloudPanelState();
}

class _CloudPanelState extends ConsumerState<CloudPanel> {
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _code = TextEditingController();
  final _adId = TextEditingController(),
      _adUrl = TextEditingController(),
      _adTitle = TextEditingController();
  String? _status, _pairing;
  bool _busy = false, _owner = false, _ads = false;
  String _provider = 'off';
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      try {
        final cloud = ref.read(cloudProvider);
        await cloud.initialize();
        if (cloud.initialized && cloud.auth.currentUser != null) {
          final token = await cloud.auth.currentUser!.getIdTokenResult();
          if (mounted) setState(() => _owner = token.claims?['owner'] == true);
        }
      } catch (_) {
        if (mounted) setState(() => _status = 'cloudError');
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _code, _adId, _adUrl, _adTitle]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await fn();
      if (mounted) setState(() => _status = 'synced');
    } catch (_) {
      if (mounted) setState(() => _status = 'cloudError');
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  Widget _field(TextEditingController c, String label, {bool secret = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: TextField(
          controller: c,
          obscureText: secret,
          autocorrect: !secret,
          enableSuggestions: !secret,
          decoration: InputDecoration(labelText: label),
          maxLength: secret ? 128 : 2048,
        ),
      );
  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context),
        cloud = ref.watch(cloudProvider),
        family = ref.watch(familyProvider).family;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s['cloud'], style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (!cloud.configured)
              Text(s['cloudMissing'])
            else ...[
              if (_busy || cloud.synchronizing) const LinearProgressIndicator(),
              if (_status != null) Text(s[_status!]),
              if (cloud.error != null) Text(s[cloud.error!]),
              if (cloud.role.isEmpty) ...[
                Text(s['cloudHelp']),
                Text(s['googleBackupHelp']),
                FilledButton.icon(
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(s['continueGoogle']),
                  onPressed: _busy || !cloud.googleConfigured
                      ? null
                      : () => _run(() async {
                          final service = cloud;
                          final launcher = ref.read(launcherProvider);
                          await launcher.beginParentExternal();
                          try {
                            await service.parentGoogleLogin();
                          } finally {
                            await launcher.endParentExternal();
                          }
                          final token = await service.auth.currentUser!
                              .getIdTokenResult();
                          if (mounted) {
                            setState(
                              () => _owner = token.claims?['owner'] == true,
                            );
                          }
                        }),
                ),
                if (!cloud.googleConfigured) Text(s['googleSetupMissing']),
                ExpansionTile(
                  title: Text(s['useEmailInstead']),
                  children: [
                    _field(_email, s['email']),
                    _field(_password, s['password'], secret: true),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await cloud.parentLogin(
                                _email.text.trim(),
                                _password.text,
                              );
                              final token = await cloud.auth.currentUser!
                                  .getIdTokenResult();
                              if (mounted) {
                                setState(
                                  () => _owner = token.claims?['owner'] == true,
                                );
                              }
                            }),
                      child: Text(s['signIn']),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => cloud.parentLogin(
                                _email.text.trim(),
                                _password.text,
                                create: true,
                              ),
                            ),
                      child: Text(s['createAccount']),
                    ),
                    Text(s['verifyHelp']),
                  ],
                ),
                const Divider(),
                _field(_code, s['pairCode']),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => cloud.pair(_code.text)),
                  child: Text(s['pairDevice']),
                ),
              ] else ...[
                Text(s[cloud.role == 'parent' ? 'parentPhone' : 'pairedPhone']),
                Text(s['offlineSync']),
                if (cloud.googleConnected) ...[
                  Text(s['googleBackupHelp']),
                  if (cloud.lastBackupAt != null) Text(s['backupSaved']),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(cloud.backupNow),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(s['backupNow']),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(cloud.restoreBackup),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(s['restoreBackup']),
                  ),
                ],
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(cloud.flush),
                  child: Text(s['syncNow']),
                ),
                if (cloud.role == 'parent' && family != null) ...[
                  for (final c in family.children)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final code = await cloud.pairingCode(c.id);
                              if (mounted) setState(() => _pairing = code);
                            }),
                      child: Text(
                        '${s['pairCode']}: ${c.name.isEmpty ? s['child'] : c.name}',
                      ),
                    ),
                  if (_pairing != null)
                    SelectableText(
                      '${s['pairExpires']}\n$_pairing',
                      style: const TextStyle(fontSize: 22),
                    ),
                ],
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(cloud.logout),
                  child: Text(s['signOut']),
                ),
                if (cloud.role == 'parent') ...[
                  const Divider(),
                  Text(s['deleteHelp']),
                  if (!cloud.googleConnected)
                    _field(_password, s['password'], secret: true),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            if (cloud.googleConnected) {
                              final launcher = ref.read(launcherProvider);
                              await launcher.beginParentExternal();
                              try {
                                await cloud.reauthenticateGoogle();
                              } finally {
                                await launcher.endParentExternal();
                              }
                            } else {
                              final user = cloud.auth.currentUser!;
                              await user.reauthenticateWithCredential(
                                EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: _password.text,
                                ),
                              );
                            }
                            await cloud.functions
                                .httpsCallable('deleteFamily')
                                .call();
                            await cloud.logout();
                          }),
                    child: Text(s['deleteAccount']),
                  ),
                ],
                if (_owner) ...[
                  const Divider(),
                  Text(
                    s['ownerAds'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: Text(s['enableAds']),
                    value: _ads,
                    onChanged: (v) => setState(() => _ads = v),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _provider,
                    items: [
                      for (final p in ['off', 'admob', 'image', 'video'])
                        DropdownMenuItem(value: p, child: Text(s['ad_$p'])),
                    ],
                    onChanged: (v) => setState(() => _provider = v ?? 'off'),
                  ),
                  _field(_adTitle, s['adTitle']),
                  if (_provider == 'admob') _field(_adId, s['adUnit']),
                  if (_provider == 'image' || _provider == 'video')
                    _field(_adUrl, s['adUrl']),
                  Text(s['mediaHelp']),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            final service = cloud;
                            await ref
                                .read(launcherProvider)
                                .beginParentExternal();
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: [
                                'jpg',
                                'jpeg',
                                'png',
                                'webp',
                                'mp4',
                              ],
                              withData: false,
                            );
                            final file = result?.files.single;
                            if (file?.path != null &&
                                file!.size <= 20 * 1024 * 1024) {
                              service.pendingMedia = file.path;
                              service.pendingMediaOwner =
                                  service.auth.currentUser?.uid;
                            }
                          }),
                    child: Text(s['selectMedia']),
                  ),
                  if (cloud.pendingMedia != null)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final url = await cloud.uploadMedia();
                              if (mounted) _adUrl.text = url;
                            }),
                      child: Text(s['uploadMedia']),
                    ),
                  Text(s['adsPolicy']),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await cloud.functions
                                .httpsCallable('configureAds')
                                .call({
                                  'enabled': _ads,
                                  'provider': _provider,
                                  'title': _adTitle.text,
                                  'bannerId': _adId.text.trim(),
                                  'url': _adUrl.text.trim(),
                                });
                          }),
                    child: Text(s['save']),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
