import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../l10n/strings.dart';
import '../../family/domain/family.dart';

// Apply the same normalization to guardian-authored answers and child input.
String _normalizeAnswer(String value) => value
    .replaceAllMapped(RegExp('[০-৯٠-٩۰-۹]'), (m) {
      final n = m[0]!.codeUnitAt(0);
      return '${n >= 0x9e6
          ? n - 0x9e6
          : n >= 0x6f0
          ? n - 0x6f0
          : n - 0x660}';
    })
    .trim()
    .toLowerCase();

class Activity extends StatefulWidget {
  const Activity({
    super.key,
    required this.task,
    required this.child,
    required this.onComplete,
    this.speak,
    this.rewardAvailable = true,
  });
  final Future<bool> Function(String, String)? speak;
  final bool rewardAvailable;
  final LearningTask task;
  final ChildProfile child;
  final Future<void> Function(List<List<Offset>> strokes) onComplete;
  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  final _answer = TextEditingController();
  final _strokes = <List<Offset>>[];
  late final List<int> _cards;
  final _matched = <int>{};
  final _open = <int>[];
  Timer? _hide;
  String? _message;
  bool _saving = false;
  bool _complete = false;
  int get _level => widget.task.difficulty;
  int get _seed =>
      '${dayKey(DateTime.now())}:${widget.child.id}:${widget.task.id}'.codeUnits
          .fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    final pairs = widget.task.difficulty + 3;
    _cards = [
      for (var i = 0; i < pairs; i++) ...[i, i],
    ]..shuffle(Random(_seed));
  }

  @override
  void dispose() {
    _answer.dispose();
    _hide?.cancel();
    super.dispose();
  }

  Future<void> _finish(bool correct) async {
    if (_saving || _complete) return;
    if (!correct) {
      setState(() => _message = 'tryAgain');
      return;
    }
    setState(() => _saving = true);
    final rewardAvailable = widget.rewardAvailable;
    try {
      await widget.onComplete(_strokes);
      if (mounted) {
        setState(() {
          _complete = true;
          _message = rewardAvailable ? 'correct' : 'alreadyDone';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final task = widget.task;
    final max = widget.child.age < 6 ? 5 : _level * 10;
    final a = _seed % max + 1, b = (_seed ~/ 3) % max + 1;
    final step = _level;
    final missing = 3 * step;
    final word = ['cat', 'sun', 'book', 'tree'][_seed % 4];
    String prompt, expected;
    switch (task.kind) {
      case 'math':
        prompt = '$a + $b = ?';
        expected = '${a + b}';
      case 'spelling':
        prompt =
            '${s['spellHelp']}\n\n${{'cat': '🐈', 'sun': '☀️', 'book': '📖', 'tree': '🌳'}[word]} · ${s[word]}';
        expected = word;
      case 'counting':
        prompt = '${s['countHelp']}\n\n${List.filled(a, '●').join(' ')}';
        expected = '$a';
      case 'shapes':
        prompt = '${s['shapeHelp']}\n\n${['●', '■', '▲'][_seed % 3]}';
        expected = s[['circle', 'square', 'triangle'][_seed % 3]];
      case 'reading':
        prompt = '${s['readingText']}\n\n${s['readingQuestion']}';
        expected = '3';
      case 'puzzle':
        prompt =
            '${s['puzzleHelp']}\n\n$step, ${2 * step}, ?, ${4 * step}, ${5 * step}';
        expected = '$missing';
      case 'words':
        prompt = '${s['wordQuestion']}\n\n${word.toUpperCase()}';
        expected = s[word];
      default:
        prompt = task.prompt;
        expected = task.answer;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          task.prompt.isEmpty ? s[task.kind] : task.prompt,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                s[_message!],
                style: TextStyle(
                  color: _message == 'correct'
                      ? const Color(0xff17683c)
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        if (_saving) const LinearProgressIndicator(),
        if (!_complete && task.kind == 'memory') ...[
          Text(s['memoryHelp']),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < _cards.length; i++)
                FilledButton.tonal(
                  onPressed:
                      _open.length == 2 ||
                          _matched.contains(i) ||
                          _open.contains(i)
                      ? null
                      : () {
                          setState(() => _open.add(i));
                          if (_open.length == 2) {
                            if (_cards[_open[0]] == _cards[_open[1]]) {
                              setState(() {
                                _matched.addAll(_open);
                                _open.clear();
                              });
                              if (_matched.length == _cards.length) {
                                _finish(true);
                              }
                            } else {
                              _hide = Timer(
                                const Duration(milliseconds: 900),
                                () {
                                  if (mounted) setState(_open.clear);
                                },
                              );
                            }
                          }
                        },
                  child: Text(
                    _matched.contains(i) || _open.contains(i)
                        ? ['●', '▲', '■', '★', '◆', '♥'][_cards[i]]
                        : '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
            ],
          ),
        ] else if (!_complete && task.kind == 'drawing') ...[
          Text(s['drawHelp']),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                onPanStart: (d) {
                  if (_strokes.length >= 64) return;
                  setState(
                    () => _strokes.add([
                      Offset(
                        d.localPosition.dx / box.maxWidth,
                        d.localPosition.dy / box.maxHeight,
                      ),
                    ]),
                  );
                },
                onPanUpdate: (d) {
                  if (_strokes.isEmpty || _strokes.last.length >= 256) return;
                  setState(
                    () => _strokes.last.add(
                      Offset(
                        (d.localPosition.dx / box.maxWidth).clamp(0, 1),
                        (d.localPosition.dy / box.maxHeight).clamp(0, 1),
                      ),
                    ),
                  );
                },
                child: CustomPaint(
                  painter: DrawingPainter(_strokes),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(_strokes.clear),
            child: Text(s['clear']),
          ),
          FilledButton(
            onPressed: () => _finish(
              _strokes
                      .where(
                        (s) =>
                            s.length >= 2 &&
                            s
                                    .asMap()
                                    .entries
                                    .where((e) => e.key > 0)
                                    .fold<double>(
                                      0,
                                      (sum, e) =>
                                          sum +
                                          (e.value - s[e.key - 1]).distance,
                                    ) >
                                0.02,
                      )
                      .length >=
                  3,
            ),
            child: Text(s['finishDrawing']),
          ),
        ] else if (!_complete) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (widget.speak != null)
            OutlinedButton.icon(
              onPressed: () async {
                final english = task.kind == 'words' || task.kind == 'spelling';
                final available = await widget.speak!(
                  english ? word : prompt,
                  english ? 'en' : s.language,
                );
                if (!available && mounted) {
                  setState(() => _message = 'noVoice');
                }
              },
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(s['listen']),
            ),
          if (task.kind == 'words' || task.kind == 'shapes')
            for (final choice
                in (task.kind == 'shapes'
                    ? ['circle', 'square', 'triangle']
                    : ['cat', 'sun', 'book', 'tree']))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: FilledButton.tonal(
                  onPressed: () => _finish(s[choice] == expected),
                  child: Text(s[choice]),
                ),
              )
          else ...[
            TextField(
              controller: _answer,
              decoration: InputDecoration(labelText: s['answer']),
              maxLength: 200,
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      _finish(
                        _normalizeAnswer(_answer.text) ==
                            _normalizeAnswer(expected),
                      );
                    },
              child: Text(s['submit']),
            ),
          ],
        ],
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this.strokes);
  final List<List<Offset>> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = const Color(0xff174d73)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final stroke in strokes) {
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(
          Offset(stroke[i - 1].dx * size.width, stroke[i - 1].dy * size.height),
          Offset(stroke[i].dx * size.width, stroke[i].dy * size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
