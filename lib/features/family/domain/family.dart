import 'dart:convert';

const taskKinds = [
  'math',
  'reading',
  'memory',
  'puzzle',
  'drawing',
  'words',
  'spelling',
  'counting',
  'shapes',
];

class ChildProfile {
  ChildProfile({
    required this.id,
    this.name = '',
    this.age = 8,
    this.difficulty = 1,
    this.minutes = 30,
    this.requiredTasks = 2,
    this.adsAllowed = false,
    Set<String>? enabled,
  }) : enabled = enabled ?? taskKinds.toSet();
  final String id;
  bool adsAllowed;
  String name;
  int age, difficulty, minutes, requiredTasks;
  Set<String> enabled;
  Map<String, dynamic> toJson() => {
    'id': id,
    'adsAllowed': adsAllowed,
    'name': name,
    'age': age,
    'difficulty': difficulty,
    'minutes': minutes,
    'requiredTasks': requiredTasks,
    'enabled': enabled.toList(),
  };
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
    id: j['id'] as String,
    adsAllowed: j['adsAllowed'] == true,
    name: j['name'] as String,
    age: (j['age'] as int).clamp(3, 17),
    difficulty: (j['difficulty'] as int).clamp(1, 3),
    minutes: (j['minutes'] as int).clamp(0, 180),
    requiredTasks: (j['requiredTasks'] as int).clamp(0, 20),
    enabled: (j['enabled'] as List).cast<String>().toSet(),
  );
}

class LearningTask {
  const LearningTask({
    required this.id,
    required this.kind,
    this.prompt = '',
    this.answer = '',
    this.childId = '',
    this.start = '',
    this.deadline = '',
    this.difficulty = 1,
  });
  final String id, kind, prompt, answer, childId, start, deadline;
  final int difficulty;
  bool available(String day) =>
      (start.isEmpty || start.compareTo(day) <= 0) &&
      (deadline.isEmpty || deadline.compareTo(day) >= 0);
  int get points => 10 * difficulty;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'prompt': prompt,
    'answer': answer,
    'childId': childId,
    'start': start,
    'deadline': deadline,
    'difficulty': difficulty,
  };
  factory LearningTask.fromJson(Map<String, dynamic> j) => LearningTask(
    id: j['id'] as String,
    kind: j['kind'] as String,
    prompt: j['prompt'] as String,
    answer: j['answer'] as String,
    childId: j['childId'] as String,
    start: j['start'] as String,
    deadline: j['deadline'] as String,
    difficulty: (j['difficulty'] as int).clamp(1, 3),
  );
}

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class Family {
  Family();
  final List<ChildProfile> children = [ChildProfile(id: 'child')];
  final List<LearningTask> customTasks = [];
  final List<Map<String, dynamic>> videos = [];
  final List<Map<String, dynamic>> requests = [];
  final Map<String, Map<String, dynamic>> days = {};
  final Map<String, int> totals = {};
  String language = '';
  String cloudFamily = '', cloudChild = '';
  final Set<String> pendingDays = {};

  ChildProfile child(String id) => children.firstWhere((c) => c.id == id);
  Map<String, dynamic> day(String id, String date) => days.putIfAbsent(
    '$id:$date',
    () => {'done': <String>[], 'points': 0, 'seconds': 0, 'bonus': 0},
  );
  List<LearningTask> tasks(String id, String date) => [
    for (final kind in taskKinds)
      if (child(id).enabled.contains(kind))
        LearningTask(
          id: 'library:$kind',
          kind: kind,
          difficulty: child(id).difficulty,
        ),
    ...customTasks.where((t) => t.childId == id && t.available(date)),
  ];
  int done(String id, String date) => (day(id, date)['done'] as List).length;
  bool unlocked(String id, String date) =>
      done(id, date) >= child(id).requiredTasks;
  int remainingSeconds(String id, String date) =>
      ((child(id).minutes + (day(id, date)['bonus'] as int)) * 60 -
              (day(id, date)['seconds'] as int))
          .clamp(0, 21600);

  bool complete(String id, LearningTask task, String date) {
    final canonical = tasks(id, date).where((t) => t.id == task.id).firstOrNull;
    if (canonical == null) throw StateError('Task unavailable');
    final record = day(id, date);
    final completed = record['done'] as List;
    if (completed.contains(task.id)) return false;
    completed.add(task.id);
    record['points'] = (record['points'] as int) + canonical.points;
    totals[id] = (totals[id] ?? 0) + canonical.points;
    return true;
  }

  int weekSeconds(String id, DateTime now) => List.generate(
    7,
    (i) => day(id, dayKey(now.subtract(Duration(days: i))))['seconds'] as int,
  ).fold(0, (a, b) => a + b);

  void request(String id, String date) {
    if (requests.any(
      (r) => r['child'] == id && r['date'] == date && r['status'] == 'pending',
    )) {
      return;
    }
    if (requests.length >= 200) requests.removeAt(0);
    requests.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'child': id,
      'date': date,
      'status': 'pending',
      'minutes': 10,
    });
  }

  void decide(String requestId, bool approve, String today) {
    final r = requests.firstWhere((r) => r['id'] == requestId);
    if (r['status'] != 'pending') return;
    r['status'] = approve && r['date'] == today ? 'approved' : 'denied';
    if (r['status'] == 'approved') {
      final d = day(r['child'] as String, today);
      d['bonus'] = ((d['bonus'] as int) + (r['minutes'] as int)).clamp(0, 180);
    }
  }

  void clearLearning() {
    children
      ..clear()
      ..add(ChildProfile(id: 'child'));
    customTasks.clear();
    videos.clear();
    requests.clear();
    days.clear();
    totals.clear();
    pendingDays.clear();
    cloudFamily = '';
    cloudChild = '';
  }

  String encode() => jsonEncode({
    'version': 1,
    'pendingDays': pendingDays.toList(),
    'cloudFamily': cloudFamily,
    'cloudChild': cloudChild,
    'language': language,
    'children': children.map((c) => c.toJson()).toList(),
    'custom': customTasks.map((t) => t.toJson()).toList(),
    'days': days,
    'totals': totals,
    'videos': videos,
    'requests': requests,
  });

  factory Family.decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1) {
      throw const FormatException('Unsupported family version');
    }
    final f = Family()..language = j['language'] as String;
    f.cloudFamily = j['cloudFamily'] as String? ?? '';
    f.cloudChild = j['cloudChild'] as String? ?? '';
    f.pendingDays.addAll((j['pendingDays'] as List? ?? []).cast<String>());
    f.children
      ..clear()
      ..addAll(
        (j['children'] as List).map(
          (v) => ChildProfile.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    if (f.children.isEmpty ||
        f.children.length > 8 ||
        !f.children.any((c) => c.id == 'child') ||
        f.children.map((c) => c.id).toSet().length != f.children.length) {
      throw const FormatException('Invalid profiles');
    }
    f.customTasks.addAll(
      (j['custom'] as List).map(
        (v) => LearningTask.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    for (final entry in (j['days'] as Map).entries) {
      f.days[entry.key as String] = Map<String, dynamic>.from(
        entry.value as Map,
      );
    }
    f.totals.addAll(Map<String, int>.from(j['totals'] as Map));
    f.videos.addAll(
      (j['videos'] as List).map((v) => Map<String, dynamic>.from(v as Map)),
    );
    f.requests.addAll(
      (j['requests'] as List).map((v) => Map<String, dynamic>.from(v as Map)),
    );
    return f;
  }
}
