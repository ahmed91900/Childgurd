import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/access/domain/access_service.dart';

class MemoryVault implements SecureVault {
  String? value;
  bool failWrites = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('Storage unavailable');
    this.value = value;
  }
}

// Fast deterministic test double. Production hashing is tested separately.
class FakeHasher implements PinHasher {
  @override
  Future<String> hash(String pin) async => 'test:$pin';
  @override
  Future<bool> verify(String pin, String encoded) async =>
      encoded == 'test:$pin';
}

Matcher denied(String code) =>
    isA<AccessDenied>().having((e) => e.code, 'code', code);

void main() {
  late MemoryVault vault;
  late DateTime now;
  late AccessService service;

  setUp(() async {
    vault = MemoryVault();
    now = DateTime.utc(2026, 1, 1);
    service = AccessService(vault, FakeHasher(), now: () => now);
    await service.load();
  });

  Future<void> configure() => service.changePins(
    currentParent: '1020',
    parent: '729384',
    kid: '458291',
  );

  test('defaults cannot unlock before forced replacement', () async {
    expect(service.configured, false);
    await expectLater(service.unlock('1020'), throwsA(denied('setupRequired')));
    await expectLater(service.unlock('0000'), throwsA(denied('setupRequired')));
  });

  test(
    'both defaults, identical and malformed replacement PINs rejected',
    () async {
      for (final pair in [
        ['1020', '1234'],
        ['0000', '1234'],
        ['1234', '1020'],
        ['1234', '0000'],
        ['1234', '1234'],
        ['123', '4567'],
        ['abcde', '4567'],
        ['1234567890123', '4567'],
      ]) {
        await expectLater(
          service.changePins(
            currentParent: '1020',
            parent: pair[0],
            kid: pair[1],
          ),
          throwsA(denied('pinPolicy')),
        );
      }
      expect(service.configured, false);
    },
  );

  test('first setup requires current parent credential', () async {
    await expectLater(
      service.changePins(
        currentParent: '0000',
        parent: '729384',
        kid: '458291',
      ),
      throwsA(denied('wrong')),
    );
    expect(service.configured, false);
    expect(service.failures, 1);
  });

  test('new PINs select the correct modes and defaults stop working', () async {
    await configure();
    expect(await service.unlock('729384'), PhoneMode.parent);
    expect(await service.unlock('458291'), PhoneMode.kid);
    await expectLater(service.unlock('1020'), throwsA(denied('wrong')));
    await expectLater(service.unlock('0000'), throwsA(denied('wrong')));
  });

  test('child PIN cannot exit Kids Mode or change credentials', () async {
    await configure();
    await expectLater(
      service.unlock('458291', parentOnly: true),
      throwsA(denied('wrong')),
    );
    await expectLater(
      service.changePins(currentParent: '458291', parent: '7829', kid: '4523'),
      throwsA(denied('wrong')),
    );
    expect(await service.unlock('729384', parentOnly: true), PhoneMode.parent);
  });

  test(
    'fifth failure locks all PINs for five minutes, even after restart',
    () async {
      await configure();
      for (var i = 0; i < 4; i++) {
        await expectLater(service.unlock('9999'), throwsA(denied('wrong')));
      }
      await expectLater(service.unlock('9999'), throwsA(denied('locked')));
      expect(service.remaining, const Duration(minutes: 5));
      service = AccessService(vault, FakeHasher(), now: () => now);
      await service.load();
      await expectLater(service.unlock('729384'), throwsA(denied('locked')));
      now = now.add(const Duration(minutes: 4, seconds: 59));
      await expectLater(service.unlock('458291'), throwsA(denied('locked')));
      now = now.add(const Duration(seconds: 1));
      expect(await service.unlock('729384'), PhoneMode.parent);
      expect(service.failures, 0);
    },
  );

  test('lockout also protects first-run credential replacement', () async {
    for (var i = 0; i < 5; i++) {
      await expectLater(
        service.changePins(
          currentParent: '9999',
          parent: '729384',
          kid: '458291',
        ),
        throwsA(denied(i == 4 ? 'locked' : 'wrong')),
      );
    }
    await expectLater(configure(), throwsA(denied('locked')));
    expect(service.configured, false);
  });

  test(
    'failed attempts survive restart; successful unlock resets them',
    () async {
      await configure();
      await expectLater(service.unlock('1111'), throwsA(denied('wrong')));
      service = AccessService(vault, FakeHasher(), now: () => now);
      await service.load();
      expect(service.failures, 1);
      await service.unlock('458291');
      expect(service.failures, 0);
    },
  );

  test('clock rollback cannot shorten active lockout', () async {
    await configure();
    for (var i = 0; i < 5; i++) {
      await expectLater(service.unlock('1111'), throwsA(isA<AccessDenied>()));
    }
    now = now.subtract(const Duration(days: 1));
    expect(service.remaining, const Duration(minutes: 5));
    await expectLater(service.unlock('729384'), throwsA(denied('locked')));
  });

  test('storage write failure never grants access', () async {
    await configure();
    vault.failWrites = true;
    await expectLater(service.unlock('729384'), throwsStateError);
  });

  test('corrupt records fail closed rather than reset credentials', () async {
    vault.value = jsonEncode({'version': 1, 'configured': true});
    final reloaded = AccessService(vault, FakeHasher());
    await expectLater(reloaded.load(), throwsA(denied('storage')));
    expect(vault.value, jsonEncode({'version': 1, 'configured': true}));
  });

  test('concurrent unlock attempts are rejected', () async {
    await configure();
    final first = service.unlock('729384');
    await expectLater(service.unlock('458291'), throwsA(denied('busy')));
    expect(await first, PhoneMode.parent);
  });
}
