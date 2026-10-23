import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

import '../../access/domain/access_service.dart';
import '../domain/family.dart';

class FamilyVault implements SecureVault {
  static const _channel = MethodChannel('com.kidsafe.launcher/family');
  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');
  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', value);
}

final familyProvider = ChangeNotifierProvider(
  (ref) => FamilyRepository(FamilyVault()),
);

class FamilyRepository extends ChangeNotifier {
  FamilyRepository(this.vault);
  final SecureVault vault;
  Family? family;
  Object? error;
  bool busy = false;
  bool fromRemote = false;
  Future<void> _queue = Future<void>.value();
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      final raw = await vault.read();
      family = raw == null ? Family() : Family.decode(raw);
      if (raw == null) await vault.write(family!.encode());
    } catch (e) {
      family = null;
      error = e;
    }
    notifyListeners();
  }

  Future<void> update(void Function(Family) action) => _enqueue(action, false);
  Future<void> remoteUpdate(void Function(Family) action) =>
      _enqueue(action, true);
  Future<void> _enqueue(void Function(Family) action, bool remote) {
    final next = _queue.then((_) => _update(action, remote));
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _update(void Function(Family) action, bool remote) async {
    if (family == null) throw StateError('Family unavailable');
    fromRemote = remote;
    busy = true;
    notifyListeners();
    try {
      final next = Family.decode(family!.encode());
      action(next);
      if (!remote) {
        for (final entry in next.days.entries) {
          if (jsonEncode(family!.days[entry.key]) != jsonEncode(entry.value)) {
            next.pendingDays.add(entry.key);
          }
        }
      }
      // Keep detailed local history for 30 days; all-time totals remain.
      final cutoff = dayKey(DateTime.now().subtract(const Duration(days: 30)));
      next.days.removeWhere(
        (key, _) => key.split(':').last.compareTo(cutoff) < 0,
      );
      next.pendingDays.removeWhere((key) => !next.days.containsKey(key));
      await vault.write(next.encode());
      family = next;
      error = null;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
