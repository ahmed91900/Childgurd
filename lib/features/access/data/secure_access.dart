import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/access_service.dart';

class AndroidSecureVault implements SecureVault {
  static const _channel = MethodChannel('com.kidsafe.launcher/vault');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', value);
}

const _iterations = 210000;

Future<List<int>> _derive(Map<String, dynamic> input) async {
  final key =
      await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: _iterations,
        bits: 256,
      ).deriveKey(
        secretKey: SecretKey(utf8.encode(input['pin'] as String)),
        nonce: input['salt'] as List<int>,
      );
  return key.extractBytes();
}

class PbkdfPinHasher implements PinHasher {
  @override
  Future<String> hash(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final digest = await compute(_derive, {'pin': pin, 'salt': salt});
    return 'pbkdf2-sha256\$$_iterations\$${base64Encode(salt)}\$${base64Encode(digest)}';
  }

  @override
  Future<bool> verify(String pin, String encoded) async {
    final fields = encoded.split(r'$');
    if (fields.length != 4 ||
        fields[0] != 'pbkdf2-sha256' ||
        fields[1] != '$_iterations') {
      throw const AccessDenied('storage');
    }
    final salt = base64Decode(fields[2]);
    final expected = base64Decode(fields[3]);
    if (salt.length != 16 || expected.length != 32) {
      throw const AccessDenied('storage');
    }
    final actual = await compute(_derive, {'pin': pin, 'salt': salt});
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }
}
