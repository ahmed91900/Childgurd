import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../../setup/data/android_launcher.dart';
import '../../setup/presentation/permission_wizard.dart';
import '../domain/access_service.dart';
import 'pin_form.dart';

enum _Screen { welcome, pins, permissions, lock, parent, kid, privacy }

class LauncherShell extends ConsumerStatefulWidget {
  const LauncherShell({super.key, required this.onLocale});
  final ValueChanged<Locale> onLocale;

  @override
  ConsumerState<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends ConsumerState<LauncherShell>
    with WidgetsBindingObserver {
  _Screen _screen = _Screen.lock;
  _Screen _beforePrivacy = _Screen.welcome;
  bool _loading = true;
  bool _busy = false;
  bool _consent = false;
  bool _parentOnly = false;
  String? _error;
  int _epoch = 0;
  late final Timer _timer;
  final _pin = TextEditingController();
  Future<List<InstalledApp>>? _apps;

  AccessService get _access => ref.read(accessProvider);
  AndroidLauncher get _device => ref.read(launcherProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    var ticks = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (++ticks % 10 == 0) ref.invalidate(permissionProvider);
      setState(() {}); // Refresh persisted lockout countdown, never reset it.
    });
  }

  Future<void> _initialize() async {
    try {
      await _device.setKidMode(true);
      await _access.load();
      if (!mounted) return;
      setState(
        () => _screen = _access.configured ? _Screen.lock : _Screen.welcome,
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'storage');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(permissionProvider);
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _epoch++;
      _pin.clear();
      if (!_loading) {
        setState(() {
          _screen = _access.configured ? _Screen.lock : _Screen.welcome;
          _parentOnly = false;
          _consent = false;
          _error = null;
        });
        unawaited(
          _device.setKidMode(true).catchError((Object _) {
            if (mounted) setState(() => _error = 'error');
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(int epoch) action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final epoch = _epoch;
    try {
      await action(epoch);
    } on AccessDenied catch (e) {
      if (mounted && epoch == _epoch) setState(() => _error = e.code);
    } catch (_) {
      if (mounted && epoch == _epoch) setState(() => _error = 'error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (epoch != _epoch) {
            _screen = _access.configured ? _Screen.lock : _Screen.welcome;
            _parentOnly = false;
          }
        });
      }
    }
  }

  Future<void> _unlock() => _run((epoch) async {
    final input = _pin.text;
    _pin.clear();
    final mode = await _access.unlock(input, parentOnly: _parentOnly);
    if (!mounted || epoch != _epoch) return;
    await _device.setKidMode(mode != PhoneMode.parent);
    if (!mounted || epoch != _epoch) {
      await _device.setKidMode(true);
      return;
    }
    setState(() {
      _parentOnly = false;
      if (mode == PhoneMode.parent) {
        _screen = _Screen.parent;
        _apps = _device.apps();
      } else {
        _screen = _Screen.kid;
      }
    });
  });

  Future<void> _savePins(String current, String parent, String kid) => _run((
    epoch,
  ) async {
    await _access.changePins(currentParent: current, parent: parent, kid: kid);
    if (!mounted || epoch != _epoch) return;
    setState(() {
      _screen = _Screen.permissions;
      _error = null;
    });
  });

  void _lock({bool parentOnly = false}) {
    setState(() {
      _screen = _Screen.lock;
      _parentOnly = parentOnly;
      _error = null;
    });
    _pin.clear();
    unawaited(
      _device.setKidMode(true).catchError((Object _) {
        if (mounted) setState(() => _error = 'error');
      }),
    );
  }

  void _privacy() => setState(() {
    _beforePrivacy = _screen;
    _screen = _Screen.privacy;
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final permissions = ref.watch(permissionProvider);
    final missing = permissions.maybeWhen(
      data: (values) =>
          SetupPermission.values.any((p) => values[p.name] != true),
      orElse: () => true,
    );
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s['app']),
          actions: [
            TextButton(
              onPressed: () => widget.onLocale(Locale(s.arabic ? 'en' : 'ar')),
              child: Text(s.arabic ? 'English' : 'العربية'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xffffedc2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              s['phase'],
                              style: const TextStyle(
                                color: Color(0xff543c00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  s[_error!],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          if (_busy) const LinearProgressIndicator(),
                          if (missing &&
                              _access.configured &&
                              (_screen == _Screen.parent ||
                                  _screen == _Screen.kid)) ...[
                            Text(
                              s['missing'],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ..._content(s),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(Strings s) {
    switch (_screen) {
      case _Screen.welcome:
        return [
          const Icon(Icons.shield_outlined, size: 88, color: Color(0xff174d73)),
          const SizedBox(height: 24),
          Text(s['welcome'], style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(s['welcomeBody']),
          TextButton(onPressed: _privacy, child: Text(s['privacy'])),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (value) => setState(() => _consent = value ?? false),
            title: Text(s['consent']),
          ),
          FilledButton(
            onPressed: !_consent || _error != null
                ? null
                : () => setState(() => _screen = _Screen.pins),
            child: Text(s['begin']),
          ),
        ];
      case _Screen.pins:
        return [
          ChangePinsForm(
            busy: _busy || _access.remaining > Duration.zero,
            submit: _savePins,
          ),
          if (_access.remaining > Duration.zero)
            Text('${s['locked']} ${_access.remaining.inSeconds + 1}s'),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(
                    () => _screen = _access.configured
                        ? _Screen.parent
                        : _Screen.welcome,
                  ),
            child: Text(s['back']),
          ),
        ];
      case _Screen.permissions:
        return [
          PermissionWizard(
            onContinue: () async {
              await _run((epoch) async {
                await _device.setKidMode(false);
                if (epoch != _epoch) {
                  await _device.setKidMode(true);
                  return;
                }
                if (mounted) {
                  setState(() {
                    _screen = _Screen.parent;
                    _apps = _device.apps();
                  });
                }
              });
            },
          ),
        ];
      case _Screen.lock:
        final remaining = _access.remaining;
        return [
          const Icon(
            Icons.lock_person_outlined,
            size: 80,
            color: Color(0xff174d73),
          ),
          const SizedBox(height: 24),
          Text(s['secure'], style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(s[_parentOnly ? 'parentOnly' : 'pinHint']),
          PinField(controller: _pin, label: s['enterPin']),
          if (remaining > Duration.zero)
            Semantics(
              liveRegion: true,
              child: Text('${s['locked']} ${remaining.inSeconds + 1}s'),
            ),
          FilledButton(
            onPressed: _busy || remaining > Duration.zero || _error == 'storage'
                ? null
                : _unlock,
            child: Text(s['unlock']),
          ),
          if (_parentOnly)
            TextButton(
              onPressed: () => setState(() => _screen = _Screen.kid),
              child: Text(s['backKid']),
            ),
          TextButton(onPressed: _privacy, child: Text(s['privacy'])),
        ];
      case _Screen.parent:
        return [
          Text(s['parent'], style: Theme.of(context).textTheme.headlineLarge),
          Text(s['parentBody']),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _screen = _Screen.permissions),
                child: Text(s['permissions']),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _screen = _Screen.pins),
                child: Text(s['changePins']),
              ),
              OutlinedButton(onPressed: _privacy, child: Text(s['privacy'])),
              FilledButton(onPressed: _lock, child: Text(s['lock'])),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<InstalledApp>>(
            future: _apps,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(s['appsError']);
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) return Text(s['emptyApps']);
              return Column(
                children: [
                  for (final app in snapshot.data!)
                    Card(
                      child: ListTile(
                        minVerticalPadding: 16,
                        leading: const Icon(Icons.apps_rounded),
                        title: Text(app.label),
                        onTap: () => _run((_) => _device.open(app.package)),
                      ),
                    ),
                ],
              );
            },
          ),
        ];
      case _Screen.kid:
        const colors = [
          Color(0xffd4eff3),
          Color(0xffffe6bd),
          Color(0xffe3def6),
          Color(0xffd8edcf),
        ];
        const icons = [
          Icons.auto_stories_rounded,
          Icons.ondemand_video_rounded,
          Icons.extension_rounded,
          Icons.stars_rounded,
        ];
        const labels = ['tasks', 'videos', 'games', 'rewards'];
        return [
          Text(s['kid'], style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(s['kidBody']),
          const SizedBox(height: 24),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(icons[i], size: 40, color: const Color(0xff203b52)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s[labels[i]],
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: const Color(0xff203b52)),
                          ),
                          Text(
                            s['coming'],
                            style: const TextStyle(color: Color(0xff203b52)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton(
            onPressed: () => _lock(parentOnly: true),
            child: Text(s['exit']),
          ),
        ];
      case _Screen.privacy:
        return [
          Text(
            s['privacyTitle'],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(s['privacyBody'], style: const TextStyle(height: 1.6)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _screen = _beforePrivacy),
            child: Text(s['back']),
          ),
        ];
    }
  }
}
