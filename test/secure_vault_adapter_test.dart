import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/access/data/secure_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kidsafe.launcher/vault');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'vault passes encrypted-record operations through the native boundary',
    () async {
      String? stored;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') {
          stored = call.arguments as String;
          return null;
        }
        if (call.method == 'read') return stored;
        throw PlatformException(code: 'UNKNOWN');
      });
      final vault = AndroidSecureVault();
      expect(await vault.read(), isNull);
      await vault.write('{"example":"record"}');
      expect(await vault.read(), '{"example":"record"}');
    },
  );

  test('native storage failure propagates without reset or fallback', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: 'SECURE_STORAGE_FAILED');
    });
    final vault = AndroidSecureVault();
    await expectLater(vault.read(), throwsA(isA<PlatformException>()));
    await expectLater(vault.write('record'), throwsA(isA<PlatformException>()));
    expect(calls, ['read', 'write']);
  });
}
