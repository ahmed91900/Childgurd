import 'dart:convert';

enum PhoneMode { locked, parent, kid }

abstract interface class SecureVault {
  Future<String?> read();
  Future<void> write(String value);
}

abstract interface class PinHasher {
  Future<String> hash(String pin);
  Future<bool> verify(String pin, String encoded);
}

class AccessDenied implements Exception {
  const AccessDenied(this.code);
  final String code;
}

/// One encrypted record makes updates to credentials and retry state atomic at
/// the storage boundary. Storage failures always deny entry.
class AccessService {
  AccessService(this._vault, this._hasher, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SecureVault _vault;
  final PinHasher _hasher;
  final DateTime Function() _now;
  Map<String, dynamic>? _record;
  bool _busy = false;

  bool get configured => _record?['configured'] == true;
  int get failures => (_record?['failures'] as int?) ?? 0;
  int get _effectiveNow {
    final actual = _now().millisecondsSinceEpoch;
    final seen = (_record?['lastSeen'] as int?) ?? 0;
    return actual > seen ? actual : seen;
  }

  Duration get remaining {
    final until = (_record?['lockedUntil'] as int?) ?? 0;
    return Duration(milliseconds: (until - _effectiveNow).clamp(0, 300000));
  }

  Future<void> load() async {
    final raw = await _vault.read();
    if (raw == null) {
      // Bootstrap credentials are usable only to authorize first setup.
      final initial = <String, dynamic>{
        'version': 1,
        'configured': false,
        'parent': await _hasher.hash('1020'),
        'kid': await _hasher.hash('0000'),
        'failures': 0,
        'lockedUntil': 0,
        'lastSeen': _now().millisecondsSinceEpoch,
      };
      await _save(initial);
    } else {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['version'] != 1 ||
          value['configured'] is! bool ||
          value['parent'] is! String ||
          value['kid'] is! String ||
          value['failures'] is! int ||
          (value['failures'] as int) < 0 ||
          (value['failures'] as int) > 4 ||
          value['lockedUntil'] is! int ||
          value['lastSeen'] is! int) {
        throw const AccessDenied('storage');
      }
      _record = value;
      await _save({...value, 'lastSeen': _effectiveNow});
    }
  }

  Future<void> _save(Map<String, dynamic> value) async {
    await _vault.write(jsonEncode(value));
    _record = value;
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy || _record == null) throw const AccessDenied('busy');
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<PhoneMode> _check(String pin, {bool parentOnly = false}) async {
    if (remaining > Duration.zero) throw const AccessDenied('locked');
    final parent = await _hasher.verify(pin, _record!['parent'] as String);
    final kid = await _hasher.verify(pin, _record!['kid'] as String);
    if (!parent && (!kid || parentOnly || !configured)) {
      final count = failures + 1;
      await _save({
        ..._record!,
        'failures': count == 5 ? 0 : count,
        'lockedUntil': count == 5 ? _effectiveNow + 300000 : 0,
        'lastSeen': _effectiveNow,
      });
      throw AccessDenied(count == 5 ? 'locked' : 'wrong');
    }
    await _save({
      ..._record!,
      'failures': 0,
      'lockedUntil': 0,
      'lastSeen': _effectiveNow,
    });
    return parent ? PhoneMode.parent : PhoneMode.kid;
  }

  Future<PhoneMode> unlock(String pin, {bool parentOnly = false}) =>
      _exclusive(() async {
        if (!configured) throw const AccessDenied('setupRequired');
        return _check(pin, parentOnly: parentOnly);
      });

  /// Re-authentication is required even if a parent session already exists.
  Future<void> changePins({
    required String currentParent,
    required String parent,
    required String kid,
  }) => _exclusive(() async {
    if (!RegExp(r'^\d{4,12}$').hasMatch(parent) ||
        !RegExp(r'^\d{4,12}$').hasMatch(kid) ||
        parent == kid ||
        const ['1020', '0000'].contains(parent) ||
        const ['1020', '0000'].contains(kid)) {
      throw const AccessDenied('pinPolicy');
    }
    await _check(currentParent, parentOnly: true);
    final parentHash = await _hasher.hash(parent);
    final kidHash = await _hasher.hash(kid);
    await _save({
      ..._record!,
      'configured': true,
      'parent': parentHash,
      'kid': kidHash,
    });
  });
}
