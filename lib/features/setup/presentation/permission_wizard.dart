import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../data/android_launcher.dart';

class PermissionWizard extends ConsumerStatefulWidget {
  const PermissionWizard({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  ConsumerState<PermissionWizard> createState() => _PermissionWizardState();
}

class _PermissionWizardState extends ConsumerState<PermissionWizard> {
  bool consent = false;
  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final permissions = ref.watch(permissionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s['permissions'],
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(s['permissionsBody']),
        const SizedBox(height: 16),
        permissions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              Text(s['permissionError']),
              TextButton(
                onPressed: () => ref.invalidate(permissionProvider),
                child: Text(s['retry']),
              ),
            ],
          ),
          data: (status) => Column(
            children: [
              for (final permission in SetupPermission.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status[permission.name] == true
                                  ? Icons.check_circle
                                  : Icons.pending_outlined,
                              color: status[permission.name] == true
                                  ? const Color(0xff17683c)
                                  : const Color(0xff704500),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s[permission.name],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(s['${permission.name}Body']),
                        const SizedBox(height: 8),
                        if (permission == SetupPermission.accessibility &&
                            status[permission.name] != true)
                          CheckboxListTile(
                            value: consent,
                            onChanged: (v) =>
                                setState(() => consent = v ?? false),
                            title: Text(s['accessibilityConsent']),
                          ),
                        OutlinedButton(
                          onPressed:
                              permission == SetupPermission.accessibility &&
                                  status[permission.name] != true &&
                                  !consent
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(launcherProvider)
                                        .request(permission);
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(s['error'])),
                                      );
                                    }
                                  }
                                  ref.invalidate(permissionProvider);
                                },
                          child: Text(
                            s[status[permission.name] == true
                                ? 'granted'
                                : 'grant'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Ordinary app permissions cannot guarantee containment. OEMs may not offer every grant.
        FilledButton(onPressed: widget.onContinue, child: Text(s['continue'])),
      ],
    );
  }
}
