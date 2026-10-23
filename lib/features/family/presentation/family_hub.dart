import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:video_player/video_player.dart';
import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../../access/domain/access_service.dart';
import '../../access/presentation/pin_form.dart';
import '../../learning/presentation/activity.dart';
import '../../learning/presentation/learning_book.dart';
import '../data/family_repository.dart';
import '../../cloud/presentation/cloud_panel.dart';
import '../../cloud/data/cloud_sync.dart';
import '../../cloud/presentation/owner_ads.dart';
import '../domain/family.dart';

class FamilyHub extends ConsumerStatefulWidget {
  const FamilyHub({super.key, required this.parent, this.childId = 'child'});
  final bool parent;
  final String childId;
  @override
  ConsumerState<FamilyHub> createState() => _FamilyHubState();
}

class _FamilyHubState extends ConsumerState<FamilyHub> {
  String _selected = 'child';
  String _page = 'home';
  bool _adding = false;
  String? _message;
  LearningTask? _task;
  Map<String, dynamic>? _video;
  Timer? _timer;
  bool _ticking = false;
  final _watch = Stopwatch();
  final _fields = List.generate(14, (_) => TextEditingController());
  FamilyRepository get _repo => ref.read(familyProvider);
  String get _id => widget.parent ? _selected : widget.childId;
  String get _date => dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await _repo.load();
      if (mounted && _repo.family != null) _fill();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watch.stop();
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  void _fill() {
    final c = _repo.family!.child(_id);
    final values = [
      c.name,
      '${c.age}',
      '${c.difficulty}',
      '${c.minutes}',
      '${c.requiredTasks}',
    ];
    for (var i = 0; i < 5; i++) {
      _fields[i].text = values[i];
    }
    if (mounted) setState(() {});
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_repo.busy) return;
    try {
      await action();
      if (mounted) setState(() => _message = 'saved');
    } on AccessDenied catch (e) {
      if (mounted) setState(() => _message = e.code);
    } catch (_) {
      if (mounted) setState(() => _message = 'invalid');
    }
  }

  Future<void> _tick() async {
    if (!mounted || widget.parent || _ticking || !_watch.isRunning) return;
    if (_watch.elapsedMilliseconds < 1000) return;
    final f = _repo.family;
    if (f == null || _repo.busy) return;
    if (!f.unlocked(_id, _date) || f.remainingSeconds(_id, _date) <= 0) {
      _watch.stop();
      if (mounted) {
        setState(() {
          _page = 'home';
          _task = null;
          _video = null;
          _message = 'timeOver';
        });
      }
      return;
    }
    // Reserve each next second before playback/play can continue. A process
    // restart cannot restore time already charged to the encrypted ledger.
    _ticking = true;
    final elapsed = _watch.elapsed.inSeconds.clamp(
      1,
      f.remainingSeconds(_id, _date),
    );
    _watch.reset();
    try {
      await _repo.update((v) {
        final d = v.day(_id, _date);
        d['seconds'] = (d['seconds'] as int) + elapsed;
      });
    } catch (_) {
      _watch.stop();
      if (mounted) {
        setState(() {
          _page = 'home';
          _video = null;
          _task = null;
          _message = 'storage';
        });
      }
    } finally {
      _ticking = false;
    }
  }

  Future<void> _open(String page, {bool timed = false}) async {
    final f = _repo.family!;
    if (timed) {
      if (!f.unlocked(_id, _date)) {
        setState(() => _message = 'gate');
        return;
      }
      if (f.remainingSeconds(_id, _date) <= 0) {
        setState(() => _message = 'timeOver');
        return;
      }
      // Charge the first second before entering the timed area.
      try {
        await _repo.update((v) {
          final d = v.day(_id, _date);
          d['seconds'] = (d['seconds'] as int) + 1;
        });
      } catch (_) {
        if (mounted) setState(() => _message = 'storage');
        return;
      }
      _watch
        ..reset()
        ..start();
    } else {
      _watch.stop();
    }
    if (mounted) {
      setState(() {
        _page = page;
        _message = null;
        _task = null;
        _video = null;
      });
    }
  }

  Widget _field(int i, String label, {bool number = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: TextField(
      controller: _fields[i],
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLength: i == 7 || i == 8 ? 200 : 100,
      decoration: InputDecoration(labelText: label, counterText: ''),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context),
        repo = ref.watch(familyProvider),
        f = repo.family;
    if (f == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: repo.error == null
            ? const LinearProgressIndicator()
            : Text(s['storage']),
      );
    }
    if (!f.children.any((c) => c.id == _id)) return Text(s['storage']);
    final c = f.child(_id), today = f.day(_id, _date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Semantics(liveRegion: true, child: Text(s[_message!])),
          ),
        if (repo.busy) const LinearProgressIndicator(),
        if (widget.parent)
          ..._parent(s, f, c, today)
        else
          ..._kid(s, f, c, today),
      ],
    );
  }

  List<Widget> _parent(
    Strings s,
    Family f,
    ChildProfile c,
    Map<String, dynamic> today,
  ) {
    return [
      const SizedBox(height: 24),
      Text(s['family'], style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in f.children)
            ChoiceChip(
              label: Text(child.name.isEmpty ? s['child'] : child.name),
              selected: child.id == _selected && !_adding,
              onSelected: (_) {
                setState(() {
                  _selected = child.id;
                  _adding = false;
                });
                _fill();
              },
            ),
          if (f.children.length < 8)
            ActionChip(
              label: Text(s['addChild']),
              avatar: const Icon(Icons.add),
              onPressed: () {
                setState(() => _adding = true);
                for (final field in _fields.take(7)) {
                  field.clear();
                }
                _fields[1].text = '8';
                _fields[2].text = '1';
                _fields[3].text = '30';
                _fields[4].text = '2';
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              Text('${s['done']}: ${f.done(c.id, _date)}'),
              Text('${s['points']}: ${f.totals[c.id] ?? 0}'),
              Text(
                '${s['today']}: ${(today['seconds'] as int) ~/ 60} ${s['minutes']}',
              ),
              Text(
                '${s['week']}: ${f.weekSeconds(c.id, DateTime.now()) ~/ 60} ${s['minutes']}',
              ),
            ],
          ),
        ),
      ),
      const CloudPanel(),
      OutlinedButton.icon(
        onPressed: () => ref.read(launcherProvider).speechSettings(),
        icon: const Icon(Icons.volume_up),
        label: Text(s['voiceSettings']),
      ),
      Text(s['profile'], style: Theme.of(context).textTheme.titleLarge),
      _field(0, s['name']),
      _field(1, s['age'], number: true),
      _field(2, s['difficulty'], number: true),
      _field(3, s['dailyLimit'], number: true),
      _field(4, s['requiredTasks'], number: true),
      if (_adding) ...[
        PinField(controller: _fields[5], label: s['currentParent']),
        PinField(controller: _fields[6], label: s['childPin']),
      ],
      FilledButton(
        onPressed: _repo.busy
            ? null
            : () => _action(() async {
                final age = int.tryParse(normalizePin(_fields[1].text)),
                    difficulty = int.tryParse(normalizePin(_fields[2].text)),
                    minutes = int.tryParse(normalizePin(_fields[3].text)),
                    required = int.tryParse(normalizePin(_fields[4].text));
                if (age == null ||
                    age < 3 ||
                    age > 17 ||
                    difficulty == null ||
                    difficulty < 1 ||
                    difficulty > 3 ||
                    minutes == null ||
                    minutes < 0 ||
                    minutes > 180 ||
                    required == null ||
                    required < 0 ||
                    required > 20) {
                  throw const FormatException();
                }
                final id = _adding
                    ? 'c${DateTime.now().microsecondsSinceEpoch}'
                    : c.id;
                if (_adding) {
                  await ref
                      .read(accessProvider)
                      .setChildPin(
                        currentParent: _fields[5].text,
                        id: id,
                        pin: _fields[6].text,
                      );
                }
                await _repo.update((v) {
                  if (_adding) v.children.add(ChildProfile(id: id));
                  final child = v.child(id);
                  child.name = _fields[0].text.trim();
                  child.age = age;
                  child.difficulty = difficulty;
                  child.minutes = minutes;
                  child.requiredTasks = required;
                });
                if (mounted) {
                  setState(() {
                    _selected = id;
                    _adding = false;
                  });
                  _fields[5].clear();
                  _fields[6].clear();
                  _fill();
                }
              }),
        child: Text(s['save']),
      ),
      const SizedBox(height: 24),
      SwitchListTile(
        title: Text(s['allowAds']),
        subtitle: Text(s['adsPolicy']),
        value: c.adsAllowed,
        onChanged: (v) =>
            _action(() => _repo.update((f) => f.child(c.id).adsAllowed = v)),
      ),
      Text(s['library'], style: Theme.of(context).textTheme.titleLarge),
      for (final kind in taskKinds)
        SwitchListTile(
          title: Text(s[kind]),
          value: c.enabled.contains(kind),
          onChanged: _repo.busy
              ? null
              : (enabled) => _action(
                  () => _repo.update((v) {
                    if (enabled) {
                      v.child(c.id).enabled.add(kind);
                    } else {
                      v.child(c.id).enabled.remove(kind);
                    }
                  }),
                ),
        ),
      if (f.tasks(c.id, _date).length < c.requiredTasks) Text(s['gateConfig']),
      Text(s['custom'], style: Theme.of(context).textTheme.titleLarge),
      _field(7, s['prompt']),
      _field(8, s['answer']),
      _field(9, s['start']),
      _field(10, s['deadline']),
      OutlinedButton(
        onPressed: () => _action(() async {
          final start = _fields[9].text.trim().isEmpty
                  ? _date
                  : _fields[9].text.trim(),
              end = _fields[10].text.trim().isEmpty
                  ? start
                  : _fields[10].text.trim();
          if (_fields[7].text.trim().length < 3 ||
              _fields[8].text.trim().isEmpty ||
              f.customTasks.length >= 100) {
            throw const FormatException();
          }
          for (final date in [start, end]) {
            final parsed = DateTime.tryParse(date);
            if (parsed == null || dayKey(parsed) != date) {
              throw const FormatException();
            }
          }
          if (end.compareTo(start) < 0) throw const FormatException();
          await _repo.update(
            (v) => v.customTasks.add(
              LearningTask(
                id: 'custom:${DateTime.now().microsecondsSinceEpoch}',
                kind: 'custom',
                prompt: _fields[7].text.trim(),
                answer: _fields[8].text.trim(),
                childId: c.id,
                start: start,
                deadline: end,
                difficulty: c.difficulty,
              ),
            ),
          );
          if (mounted) {
            for (var i = 7; i <= 10; i++) {
              _fields[i].clear();
            }
          }
        }),
        child: Text(s['custom']),
      ),
      for (final task in f.customTasks.where((t) => t.childId == c.id))
        ListTile(
          title: Text(task.prompt),
          subtitle: Text('${task.start} → ${task.deadline}'),
          trailing: IconButton(
            tooltip: s['remove'],
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _action(
              () => _repo.update(
                (v) => v.customTasks.removeWhere((t) => t.id == task.id),
              ),
            ),
          ),
        ),
      const SizedBox(height: 24),
      Text(s['requests'], style: Theme.of(context).textTheme.titleLarge),
      if (!f.requests.any(
        (r) => r['child'] == c.id && r['status'] == 'pending',
      ))
        Text(s['noRequests']),
      for (final request in f.requests.where(
        (r) => r['child'] == c.id && r['status'] == 'pending',
      ))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  '${request['date']} · ${request['minutes']} ${s['minutes']}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final approve in [true, false])
                      OutlinedButton(
                        onPressed: () => _action(
                          () => _repo.update(
                            (v) => v.decide(
                              request['id'] as String,
                              approve,
                              _date,
                            ),
                          ),
                        ),
                        child: Text(s[approve ? 'approve' : 'deny']),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 24),
      Text(s['videos'], style: Theme.of(context).textTheme.titleLarge),
      Text(s['videoHelp']),
      _field(11, s['videoName']),
      _field(12, s['videoUrl']),
      OutlinedButton(
        onPressed: () => _action(() async {
          final uri = Uri.tryParse(_fields[12].text.trim());
          if (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty ||
              !uri.path.toLowerCase().endsWith('.mp4') ||
              _fields[11].text.trim().isEmpty ||
              f.videos.length >= 40) {
            throw const FormatException();
          }
          await _repo.update(
            (v) => v.videos.add({
              'id': DateTime.now().microsecondsSinceEpoch.toString(),
              'child': c.id,
              'name': _fields[11].text.trim(),
              'url': uri.toString(),
            }),
          );
          if (mounted) {
            _fields[11].clear();
            _fields[12].clear();
          }
        }),
        child: Text(s['addVideo']),
      ),
      for (final video in f.videos.where((v) => v['child'] == c.id))
        ListTile(
          title: Text(video['name'] as String),
          trailing: IconButton(
            tooltip: s['remove'],
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _action(
              () => _repo.update(
                (v) => v.videos.removeWhere((x) => x['id'] == video['id']),
              ),
            ),
          ),
        ),
      const SizedBox(height: 24),
      PinField(controller: _fields[13], label: s['currentParent']),
      OutlinedButton(
        onPressed: _repo.busy
            ? null
            : () => _action(() async {
                await ref.read(accessProvider).verifyParent(_fields[13].text);
                _fields[13].clear();
                await ref.read(cloudProvider).logout();
                await _repo.update((v) {
                  v.days.removeWhere((key, _) => key.startsWith('${c.id}:'));
                  v.totals.remove(c.id);
                  v.customTasks.removeWhere((t) => t.childId == c.id);
                  v.videos.removeWhere((x) => x['child'] == c.id);
                  v.requests.removeWhere((x) => x['child'] == c.id);
                  final i = v.children.indexWhere((x) => x.id == c.id);
                  v.children[i] = ChildProfile(id: c.id);
                  v.pendingDays.removeWhere(
                    (key) => key.startsWith('${c.id}:'),
                  );
                });
                if (mounted) _fill();
              }),
        child: Text(s['resetLocal']),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _kid(
    Strings s,
    Family f,
    ChildProfile c,
    Map<String, dynamic> today,
  ) {
    if (_page != 'home') {
      return [
        OutlinedButton.icon(
          onPressed: () {
            _watch.stop();
            ref.read(launcherProvider).stopSpeech();
            setState(() {
              _page = 'home';
              _task = null;
              _video = null;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: Text(s['back']),
        ),
        const SizedBox(height: 16),
        if (_task != null)
          Activity(
            key: ValueKey(_task!.id),
            task: _task!,
            child: c,
            speak: ref.read(launcherProvider).speak,
            rewardAvailable: !(today['done'] as List).contains(_task!.id),
            onComplete: (strokes) => _repo.update((v) {
              v.complete(c.id, _task!, _date);
              if (_task!.kind == 'drawing') {
                for (final entry in v.days.entries.where(
                  (e) => e.key.startsWith('${c.id}:'),
                )) {
                  entry.value.remove('drawing');
                }
                v.day(c.id, _date)['drawing'] = strokes.take(64).map((line) {
                  final step = (line.length / 32).ceil().clamp(1, 256);
                  return [
                    for (var i = 0; i < line.length; i += step)
                      [
                        double.parse(line[i].dx.toStringAsFixed(3)),
                        double.parse(line[i].dy.toStringAsFixed(3)),
                      ],
                  ];
                }).toList();
              }
            }),
          )
        else if (_video != null)
          ApprovedPlayer(
            key: ValueKey(_video!['id']),
            url: _video!['url'] as String,
            onPlaying: (playing) {
              if (playing) {
                _watch.start();
              } else {
                _watch.stop();
              }
            },
          )
        else if (_page == 'alphabet')
          LearningBook(
            onLearn: (id) => _repo.update((v) {
              final d = v.day(c.id, _date),
                  learned = List<String>.from(
                    v.day(c.id, _date)['letters'] as List? ?? [],
                  );
              if (!learned.contains(id)) {
                learned.add(id);
                d['letters'] = learned;
                d['points'] = (d['points'] as int) + 2;
                v.totals[c.id] = (v.totals[c.id] ?? 0) + 2;
              }
            }),
          )
        else if (_page == 'stories')
          const StoryBook()
        else if (_page == 'rewards') ...[
          Text(s['rewards'], style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          const Icon(Icons.stars_rounded, size: 96, color: Color(0xffb57900)),
          Text(
            '${(f.totals[c.id] ?? 0) ~/ 50} ${s['stars']} · ${f.totals[c.id] ?? 0} ${s['points']}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(s['badges']),
          if (today['drawing'] != null)
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: DrawingPainter(
                  (today['drawing'] as List)
                      .map(
                        (line) => (line as List)
                            .map(
                              (p) => Offset(
                                (p[0] as num).toDouble(),
                                (p[1] as num).toDouble(),
                              ),
                            )
                            .toList(),
                      )
                      .toList(),
                ),
              ),
            ),
        ] else if (_page == 'videos') ...[
          Text(s['videoHelp']),
          if (!f.videos.any((v) => v['child'] == c.id)) Text(s['noVideos']),
          for (final video in f.videos.where((v) => v['child'] == c.id))
            Card(
              child: ListTile(
                title: Text(video['name'] as String),
                leading: const Icon(Icons.play_circle_outline),
                onTap: () {
                  _watch.stop();
                  setState(() => _video = video);
                },
              ),
            ),
        ] else ...[
          if (f.tasks(c.id, _date).isEmpty) Text(s['noTasks']),
          for (final task
              in f
                  .tasks(c.id, _date)
                  .where(
                    (t) =>
                        _page != 'games' ||
                        ['memory', 'puzzle'].contains(t.kind),
                  ))
            Card(
              child: ListTile(
                minVerticalPadding: 18,
                leading: Icon(
                  (today['done'] as List).contains(task.id)
                      ? Icons.check_circle
                      : Icons.auto_stories_outlined,
                ),
                title: Text(task.prompt.isEmpty ? s[task.kind] : task.prompt),
                subtitle: Text('${task.points} ${s['points']}'),
                onTap: () => setState(() => _task = task),
              ),
            ),
        ],
      ];
    }
    return [
      Text(
        c.name.isEmpty ? s['kid'] : c.name,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      Text(s['kidBody']),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('${s['done']}: ${f.done(c.id, _date)}/${c.requiredTasks}'),
              Text('${s['points']}: ${f.totals[c.id] ?? 0}'),
              Text(
                '${s['remaining']}: ${(f.remainingSeconds(c.id, _date) / 60).ceil()} ${s['minutes']}',
              ),
            ],
          ),
        ),
      ),
      for (final entry in <(String, IconData, Color)>[
        ('tasks', Icons.auto_stories, const Color(0xffd4eff3)),
        ('alphabet', Icons.abc, const Color(0xffffe6bd)),
        ('stories', Icons.menu_book, const Color(0xffe3def6)),
        ('games', Icons.extension, const Color(0xffd8edcf)),
        ('videos', Icons.ondemand_video, const Color(0xffd4eff3)),
        ('rewards', Icons.stars, const Color(0xffffe6bd)),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: entry.$3,
              foregroundColor: const Color(0xff203b52),
              minimumSize: const Size(48, 76),
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.all(20),
            ),
            onPressed: () => _open(
              entry.$1,
              timed: ['games', 'videos', 'stories'].contains(entry.$1),
            ),
            icon: Icon(entry.$2, size: 32),
            label: Text(s[entry.$1], style: const TextStyle(fontSize: 21)),
          ),
        ),
      OwnerAds(
        parentConsent: c.adsAllowed,
        onVideo: (url) async {
          await _open('videos', timed: true);
          if (mounted && _page == 'videos') {
            setState(() => _video = {'id': 'owner-ad', 'url': url});
          }
        },
      ),
      OutlinedButton.icon(
        onPressed: () => _action(() async {
          await _repo.update((v) => v.request(c.id, _date));
          if (mounted) setState(() => _message = 'requestSent');
        }),
        icon: const Icon(Icons.more_time),
        label: Text(s['requestTime']),
      ),
      for (final request in f.requests.where(
        (r) => r['child'] == c.id && r['date'] == _date,
      ))
        Text('${s['requestTime']}: ${s[request['status'] as String]}'),
    ];
  }
}

class ApprovedPlayer extends StatefulWidget {
  const ApprovedPlayer({super.key, required this.url, required this.onPlaying});
  final String url;
  final ValueChanged<bool> onPlaying;
  @override
  State<ApprovedPlayer> createState() => _ApprovedPlayerState();
}

class _ApprovedPlayerState extends State<ApprovedPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _ready;
  bool _reported = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ready = _controller.initialize();
    _controller.addListener(_update);
  }

  void _update() {
    final playing = _controller.value.isPlaying;
    if (playing != _reported) {
      _reported = playing;
      widget.onPlaying(playing);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError || _controller.value.hasError) {
          return Text(s['videoError']);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play(),
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(s[_controller.value.isPlaying ? 'pause' : 'play']),
            ),
          ],
        );
      },
    );
  }
}
