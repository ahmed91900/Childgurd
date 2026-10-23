import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/access/data/secure_access.dart';
import 'package:kidsafe_launcher/features/access/domain/access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PBKDF2 uses independent random salts and validates credentials',
    () async {
      final hasher = PbkdfPinHasher();
      final first = await hasher.hash('729384');
      final second = await hasher.hash('729384');
      expect(first, startsWith(r'pbkdf2-sha256$210000$'));
      expect(first, isNot(second));
      expect(first, isNot(contains('729384')));
      expect(await hasher.verify('729384', first), true);
      expect(await hasher.verify('729385', first), false);
      expect(await hasher.verify('729384', second), true);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('malformed or downgraded hashes fail closed', () async {
    final hasher = PbkdfPinHasher();
    for (final record in [
      'plaintext',
      r'pbkdf2-sha256$1$abc$abc',
      r'pbkdf2-sha256$210000$YQ==$Yg==',
    ]) {
      await expectLater(
        hasher.verify('1234', record),
        throwsA(isA<AccessDenied>()),
      );
    }
  });
}
