import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/backup/domain/family_backup.dart';
import 'package:kidsafe_launcher/features/family/domain/family.dart';
import 'package:kidsafe_launcher/features/family/data/family_repository.dart';
import 'access_service_test.dart' show MemoryVault;

void main() {
  final date = dayKey(DateTime.now());
  test(
    'backup restores profiles, tasks, points, drawings and approved media',
    () {
      final original = Family()..language = 'bn';
      original.child('child').name = 'শিক্ষার্থী';
      original.children.add(
        ChildProfile(id: 'sibling', name: 'Learner', age: 5),
      );
      original.customTasks.add(
        const LearningTask(
          id: 'custom:one',
          kind: 'custom',
          childId: 'child',
          prompt: '2 + 3',
          answer: '৫',
        ),
      );
      original.videos.add({
        'child': 'child',
        'url': 'https://example.org/lesson.mp4',
      });
      original.complete('child', original.tasks('child', date).first, date);
      original.day('child', date)['drawing'] = [
        [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
      ];
      final restored = Family();
      FamilyBackup.decode(FamilyBackup.encode(original)).mergeInto(restored);
      expect(restored.child('child').name, 'শিক্ষার্থী');
      expect(restored.child('sibling').age, 5);
      expect(restored.customTasks.single.answer, '৫');
      expect(restored.totals['child'], 10);
      expect(
        restored.day('child', date)['drawing'],
        original.day('child', date)['drawing'],
      );
      expect(restored.videos.single['url'], 'https://example.org/lesson.mp4');
      expect(restored.language, 'bn');
    },
  );
  test(
    'portable backup excludes device identities, pairing links and upload queue',
    () {
      final f = Family()
        ..cloudFamily = 'owner'
        ..cloudChild = 'paired-profile';
      f.pendingDays.add('child:$date');
      final record = jsonDecode(FamilyBackup.encode(f)) as Map<String, dynamic>;
      expect(record.keys.toSet(), {
        'version',
        'language',
        'children',
        'custom',
        'days',
        'totals',
        'videos',
        'requests',
      });
      expect(record.containsKey('parent'), false);
      expect(record.containsKey('kid'), false);
      final restored = Family()..cloudFamily = 'current-owner';
      FamilyBackup.decode(jsonEncode(record)).mergeInto(restored);
      expect(restored.cloudFamily, 'current-owner');
      expect(restored.cloudChild, '');
      expect(restored.pendingDays, isEmpty);
    },
  );
  test(
    'restoring twice preserves newer offline progress without duplicate rewards',
    () {
      final old = Family();
      old.complete('child', old.tasks('child', date).first, date);
      old.day('child', date)['seconds'] = 10;
      final current = Family.decode(old.encode());
      current.complete('child', current.tasks('child', date)[1], date);
      current.day('child', date)['seconds'] = 30;
      final backup = FamilyBackup.decode(FamilyBackup.encode(old));
      backup.mergeInto(current);
      final once = current.encode();
      backup.mergeInto(current);
      expect(current.encode(), once);
      expect(current.done('child', date), 2);
      expect(current.totals['child'], 20);
      expect(current.day('child', date)['seconds'], 30);
    },
  );
  test('unknown schemas and credential-bearing envelopes are rejected', () {
    expect(() => FamilyBackup.decode('{"version":99}'), throwsFormatException);
    final raw =
        jsonDecode(FamilyBackup.encode(Family())) as Map<String, dynamic>;
    raw['parent'] = 'not-a-learning-field';
    expect(() => FamilyBackup.decode(jsonEncode(raw)), throwsFormatException);
  });
  test('oversized backup is rejected before upload or restore', () {
    final f = Family();
    f.child('child').name = List.filled(300001, 'ক').join();
    expect(() => FamilyBackup.encode(f), throwsFormatException);
    expect(
      () => FamilyBackup.decode(List.filled(900001, 'a').join()),
      throwsFormatException,
    );
  });
  test('failed restore persistence keeps existing local data intact', () async {
    final vault = MemoryVault();
    final repo = FamilyRepository(vault);
    await repo.load();
    final source = Family()..child('child').name = 'Restored';
    final backup = FamilyBackup.decode(FamilyBackup.encode(source));
    vault.failWrites = true;
    await expectLater(repo.remoteUpdate(backup.mergeInto), throwsStateError);
    expect(repo.family!.child('child').name, '');
    repo.dispose();
  });
}
