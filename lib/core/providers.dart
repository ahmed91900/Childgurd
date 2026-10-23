import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/access/data/secure_access.dart';
import '../features/access/domain/access_service.dart';
import '../features/setup/data/android_launcher.dart';

final accessProvider = Provider<AccessService>(
  (ref) => AccessService(AndroidSecureVault(), PbkdfPinHasher()),
);
final launcherProvider = Provider<AndroidLauncher>((ref) => AndroidLauncher());
final permissionProvider = FutureProvider<Map<String, bool>>(
  (ref) => ref.watch(launcherProvider).status(),
);
