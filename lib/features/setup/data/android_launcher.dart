import 'package:flutter/services.dart';

enum SetupPermission { home, admin, accessibility, overlay, usage }

class InstalledApp {
  const InstalledApp(this.label, this.package);
  final String label;
  final String package;
}

class AndroidLauncher {
  static const _channel = MethodChannel('com.kidsafe.launcher/device');

  Future<Map<String, bool>> status() async {
    final result = await _channel.invokeMapMethod<String, bool>('status');
    if (result == null) throw StateError('Permission status unavailable');
    return result;
  }

  Future<void> request(SetupPermission permission) =>
      _channel.invokeMethod<void>('request', permission.name);

  Future<void> setKidMode(bool enabled) =>
      _channel.invokeMethod<void>('setKidMode', enabled);

  Future<List<InstalledApp>> apps() async {
    final result = await _channel.invokeListMethod<dynamic>('apps') ?? [];
    return result.map((item) {
      final value = Map<String, dynamic>.from(item as Map);
      return InstalledApp(value['label'] as String, value['package'] as String);
    }).toList();
  }

  Future<void> open(String package) =>
      _channel.invokeMethod<void>('open', package);
}
