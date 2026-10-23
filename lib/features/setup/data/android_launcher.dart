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

  Future<void> enterKidMode() => _channel.invokeMethod<void>('enterKidMode');
  Future<void> endParentExternal() =>
      _channel.invokeMethod<void>('endParentExternal');
  Future<void> beginParentExternal() =>
      _channel.invokeMethod<void>('beginParentExternal');
  Future<void> speechSettings() =>
      _channel.invokeMethod<void>('request', 'speech');

  Future<bool> speak(String text, String language) async =>
      await _channel.invokeMethod<bool>('speak', {
        'text': text,
        'language': language,
      }) ??
      false;
  Future<void> stopSpeech() => _channel.invokeMethod<void>('stopSpeech');

  Future<void> open(String package) =>
      _channel.invokeMethod<void>('open', package);
}
