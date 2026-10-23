import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/family/domain/family.dart';
import 'package:kidsafe_launcher/features/family/data/family_repository.dart';
import 'access_service_test.dart' show MemoryVault;

void main() {
  const date = '2026-10-23';
  test(
    'learning works without a cloud account and advertising defaults off',
    () {
      final f = Family();
      expect(f.tasks('child', date).length, 9);
      expect(f.child('child').adsAllowed, false);
      expect(f.remainingSeconds('child', date), 1800);
      expect(f.unlocked('child', date), false);
    },
  );
  test('completion awards canonical points only once per task per day', () {
    final f = Family();
    final task = f.tasks('child', date).first;
    expect(f.complete('child', task, date), true);
    expect(f.complete('child', task, date), false);
    expect(f.totals['child'], 10);
    expect(f.day('child', date)['points'], 10);
    f.complete('child', task, '2026-10-24');
    expect(f.totals['child'], 20);
  });
  test('caller cannot inflate a reward by forging difficulty', () {
    final f = Family();
    f.complete(
      'child',
      const LearningTask(id: 'library:math', kind: 'math', difficulty: 999),
      date,
    );
    expect(f.totals['child'], 10);
  });
  test('unavailable and disabled tasks cannot award rewards', () {
    final f = Family();
    f.child('child').enabled.remove('math');
    expect(
      () => f.complete(
        'child',
        const LearningTask(id: 'library:math', kind: 'math'),
        date,
      ),
      throwsStateError,
    );
  });
  test('required task gate opens after the configured number of tasks', () {
    final f = Family();
    final tasks = f.tasks('child', date);
    f.complete('child', tasks[0], date);
    expect(f.unlocked('child', date), false);
    f.complete('child', tasks[1], date);
    expect(f.unlocked('child', date), true);
    expect(f.unlocked('child', '2026-10-24'), false);
  });
  test('scheduled tasks respect start, deadline and child identity', () {
    final f = Family()..children.add(ChildProfile(id: 'other'));
    f.customTasks.add(
      const LearningTask(
        id: 'custom:a',
        kind: 'custom',
        childId: 'child',
        start: '2026-10-23',
        deadline: '2026-10-24',
      ),
    );
    expect(
      f.tasks('child', '2026-10-22').where((t) => t.id == 'custom:a'),
      isEmpty,
    );
    expect(f.tasks('child', date).where((t) => t.id == 'custom:a').length, 1);
    expect(
      f.tasks('child', '2026-10-25').where((t) => t.id == 'custom:a'),
      isEmpty,
    );
    expect(f.tasks('other', date).where((t) => t.id == 'custom:a'), isEmpty);
  });
  test('daily play time never becomes negative and resets by date', () {
    final f = Family();
    f.day('child', date)['seconds'] = 2000;
    expect(f.remainingSeconds('child', date), 0);
    expect(f.remainingSeconds('child', '2026-10-24'), 1800);
  });
  test('time requests deduplicate pending requests and approve once', () {
    final f = Family();
    f.request('child', date);
    f.request('child', date);
    expect(f.requests.length, 1);
    final id = f.requests.single['id'] as String;
    f.decide(id, true, date);
    f.decide(id, true, date);
    expect(f.day('child', date)['bonus'], 10);
    expect(f.remainingSeconds('child', date), 2400);
  });
  test('denied and expired requests never add time', () {
    final f = Family();
    f.request('child', date);
    f.decide(f.requests.single['id'] as String, false, date);
    expect(f.day('child', date)['bonus'], 0);
    f.request('child', '2026-10-22');
    f.decide(f.requests.last['id'] as String, true, date);
    expect(f.day('child', date)['bonus'], 0);
  });
  test('weekly report counts the last seven local dates only', () {
    final f = Family();
    final now = DateTime(2026, 10, 23);
    for (var i = 0; i < 8; i++) {
      f.day('child', dayKey(now.subtract(Duration(days: i))))['seconds'] = 60;
    }
    expect(f.weekSeconds('child', now), 420);
  });
  test(
    'encrypted-ledger serialization preserves profiles, drawings and progress',
    () {
      final f = Family()..language = 'bn';
      f.children.add(ChildProfile(id: 'c2', name: 'শিক্ষার্থী', age: 5));
      f.child('c2').adsAllowed = true;
      f.day('child', date)['drawing'] = [
        [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
      ];
      f.complete('child', f.tasks('child', date).first, date);
      f.request('child', date);
      final next = Family.decode(f.encode());
      expect(next.encode(), f.encode());
      expect(next.child('c2').adsAllowed, true);
    },
  );
  test('unknown schema or missing main profile fails closed', () {
    expect(() => Family.decode('{"version":99}'), throwsFormatException);
    final f = Family()..children.clear();
    expect(() => Family.decode(f.encode()), throwsFormatException);
  });
  test(
    'repository retains the previous state after a failed durable write',
    () async {
      final vault = MemoryVault(), repo = FamilyRepository(MemoryVault());
      await repo.load();
      final failing = FamilyRepository(vault);
      await failing.load();
      vault.failWrites = true;
      await expectLater(
        failing.update((f) => f.child('child').name = 'changed'),
        throwsStateError,
      );
      expect(failing.family!.child('child').name, '');
      expect(failing.busy, false);
      repo.dispose();
      failing.dispose();
    },
  );
  test('queued local and remote updates preserve both changes', () async {
    final repo = FamilyRepository(MemoryVault());
    await repo.load();
    final local = repo.update((f) => f.child('child').name = 'Local');
    final remote = repo.remoteUpdate((f) => f.child('child').minutes = 25);
    await Future.wait([local, remote]);
    expect(repo.family!.child('child').name, 'Local');
    expect(repo.family!.child('child').minutes, 25);
    expect(repo.fromRemote, true);
    repo.dispose();
  });
  test(
    'offline outbox survives restart and remote writes do not echo',
    () async {
      final vault = MemoryVault();
      final current = FamilyRepository(vault);
      await current.load();
      final today = dayKey(DateTime.now());
      await current.update(
        (f) => f.complete('child', f.tasks('child', today).first, today),
      );
      expect(current.family!.pendingDays, contains('child:$today'));
      final restored = FamilyRepository(vault);
      await restored.load();
      expect(restored.family!.pendingDays, contains('child:$today'));
      await restored.remoteUpdate((f) => f.pendingDays.clear());
      await restored.remoteUpdate((f) => f.day('child', today)['seconds'] = 15);
      expect(restored.family!.pendingDays, isEmpty);
      current.dispose();
      restored.dispose();
    },
  );
  test(
    'history retention prunes expired outbox but preserves all-time points',
    () async {
      final repo = FamilyRepository(MemoryVault());
      await repo.load();
      final old = dayKey(DateTime.now().subtract(const Duration(days: 40)));
      await repo.update(
        (f) => f.complete('child', f.tasks('child', old).first, old),
      );
      expect(repo.family!.days.containsKey('child:$old'), false);
      expect(repo.family!.pendingDays, isEmpty);
      expect(repo.family!.totals['child'], 10);
      repo.dispose();
    },
  );
  test('account-switch reset removes previous family data and outbox', () {
    final f = Family()..language = 'bn';
    f.child('child').name = 'Previous family';
    f.children.add(ChildProfile(id: 'previous'));
    f.cloudFamily = 'previous-owner';
    f.cloudChild = 'previous-child';
    f.complete('child', f.tasks('child', date).first, date);
    f.request('child', date);
    f.pendingDays.add('child:$date');
    f.clearLearning();
    expect(f.children.map((c) => c.id), ['child']);
    expect(f.child('child').name, '');
    expect(f.days, isEmpty);
    expect(f.requests, isEmpty);
    expect(f.totals, isEmpty);
    expect(f.pendingDays, isEmpty);
    expect(f.cloudFamily, '');
    expect(f.cloudChild, '');
    expect(f.language, 'bn');
  });
}
