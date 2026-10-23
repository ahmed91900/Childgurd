import 'dart:convert';
import '../../family/domain/family.dart';

/// A portable learning backup. Device PINs, credentials and pairing links are excluded.
class FamilyBackup {
  FamilyBackup._(this.family);
  final Family family;
  static const maxBytes = 900000;

  static String encode(Family source) {
    final json = jsonDecode(source.encode()) as Map<String, dynamic>;
    json.remove('cloudFamily');
    json.remove('cloudChild');
    json.remove('pendingDays');
    final payload = jsonEncode(json);
    if (utf8.encode(payload).length > maxBytes) {
      throw const FormatException('Backup exceeds maximum size');
    }
    return payload;
  }

  factory FamilyBackup.decode(String payload) {
    if (utf8.encode(payload).length > maxBytes) {
      throw const FormatException('Backup exceeds maximum size');
    }
    final raw = jsonDecode(payload) as Map<String, dynamic>;
    const allowed = {
      'version',
      'language',
      'children',
      'custom',
      'days',
      'totals',
      'videos',
      'requests',
    };
    if (raw.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Unexpected backup fields');
    }
    return FamilyBackup._(Family.decode(payload));
  }

  /// Restore configuration and union progress so replay never duplicates rewards
  /// or erases newer offline completions. The caller checks account ownership.
  void mergeInto(Family target) {
    final source = Family.decode(family.encode());
    final previousDays = Map<String, Map<String, dynamic>>.from(target.days);
    final previousTotals = Map<String, int>.from(target.totals);
    for (final child in source.children) {
      target.children.removeWhere((c) => c.id == child.id);
      if (target.children.length < 8) target.children.add(child);
    }
    // The primary profile remains first, as required by paired-device mapping.
    target.children.sort(
      (a, b) => a.id == 'child'
          ? -1
          : b.id == 'child'
          ? 1
          : a.id.compareTo(b.id),
    );
    for (final task in source.customTasks) {
      target.customTasks.removeWhere((t) => t.id == task.id);
      if (target.customTasks.length < 100) target.customTasks.add(task);
    }
    for (final video in source.videos) {
      target.videos.removeWhere(
        (v) => v['child'] == video['child'] && v['url'] == video['url'],
      );
      if (target.videos.length < 40) target.videos.add(video);
    }
    for (final request in source.requests) {
      final existing = target.requests.where((r) => r['id'] == request['id']);
      if (existing.isNotEmpty && existing.first['status'] != 'pending') {
        continue;
      }
      target.requests.removeWhere((r) => r['id'] == request['id']);
      target.requests.add(request);
    }
    if (target.requests.length > 200) {
      target.requests.removeRange(0, target.requests.length - 200);
    }
    target.days.addAll(source.days);
    for (final entry in previousDays.entries) {
      final next = target.days[entry.key];
      if (next == null) {
        target.days[entry.key] = entry.value;
        continue;
      }
      next['done'] = {
        ...List<String>.from(next['done'] as List),
        ...List<String>.from(entry.value['done'] as List),
      }.toList();
      for (final field in ['points', 'seconds', 'bonus']) {
        final previous = entry.value[field] as int? ?? 0;
        if (previous > (next[field] as int? ?? 0)) next[field] = previous;
      }
      if (entry.value.containsKey('drawing')) {
        next['drawing'] = entry.value['drawing'];
      }
    }
    target.totals.addAll(source.totals);
    for (final entry in previousTotals.entries) {
      if (entry.value > (target.totals[entry.key] ?? 0)) {
        target.totals[entry.key] = entry.value;
      }
    }
    target.language = source.language;
  }
}
