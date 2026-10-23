import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../l10n/strings.dart';

const englishAlphabet = <List<String>>[
  ['A', 'apple', '🍎'],
  ['B', 'ball', '⚽'],
  ['C', 'cat', '🐈'],
  ['D', 'dog', '🐕'],
  ['E', 'elephant', '🐘'],
  ['F', 'fish', '🐟'],
  ['G', 'goat', '🐐'],
  ['H', 'house', '🏠'],
  ['I', 'ice cream', '🍦'],
  ['J', 'jug', '🫗'],
  ['K', 'kite', '🪁'],
  ['L', 'lion', '🦁'],
  ['M', 'moon', '🌙'],
  ['N', 'nest', '🪺'],
  ['O', 'orange', '🍊'],
  ['P', 'parrot', '🦜'],
  ['Q', 'queen', '👑'],
  ['R', 'rabbit', '🐇'],
  ['S', 'sun', '☀️'],
  ['T', 'tree', '🌳'],
  ['U', 'umbrella', '☂️'],
  ['V', 'van', '🚐'],
  ['W', 'water', '💧'],
  ['X', 'xylophone', '🎵'],
  ['Y', 'yo-yo', '🪀'],
  ['Z', 'zebra', '🦓'],
];
const banglaAlphabet = <List<String>>[
  ['অ', 'অজগর', '🐍'],
  ['আ', 'আম', '🥭'],
  ['ই', 'ইঁদুর', '🐁'],
  ['ঈ', 'ঈগল', '🦅'],
  ['উ', 'উট', '🐪'],
  ['ঊ', 'ঊষা', '🌅'],
  ['ঋ', 'ঋষি', '🧘'],
  ['এ', 'একতারা', '🎵'],
  ['ঐ', 'ঐক্য', '🤝'],
  ['ও', 'ওল', '🌱'],
  ['ঔ', 'ঔষধ', '💊'],
  ['ক', 'কলম', '🖊️'],
  ['খ', 'খরগোশ', '🐇'],
  ['গ', 'গাছ', '🌳'],
  ['ঘ', 'ঘড়ি', '🕒'],
  ['ঙ', 'রঙ', '🎨'],
  ['চ', 'চাঁদ', '🌙'],
  ['ছ', 'ছাতা', '☂️'],
  ['জ', 'জাহাজ', '🚢'],
  ['ঝ', 'ঝিনুক', '🐚'],
  ['ঞ', 'জ্ঞান', '📚'],
  ['ট', 'টমেটো', '🍅'],
  ['ঠ', 'ঠোঁট', '👄'],
  ['ড', 'ডাব', '🥥'],
  ['ঢ', 'ঢোল', '🥁'],
  ['ণ', 'হরিণ', '🦌'],
  ['ত', 'তরমুজ', '🍉'],
  ['থ', 'থালা', '🍽️'],
  ['দ', 'দরজা', '🚪'],
  ['ধ', 'ধান', '🌾'],
  ['ন', 'নৌকা', '⛵'],
  ['প', 'পাখি', '🐦'],
  ['ফ', 'ফুল', '🌸'],
  ['ব', 'বই', '📖'],
  ['ভ', 'ভালুক', '🐻'],
  ['ম', 'মাছ', '🐟'],
  ['য', 'যত্ন', '🪴'],
  ['র', 'রংধনু', '🌈'],
  ['ল', 'লেবু', '🍋'],
  ['শ', 'শাপলা', '🪷'],
  ['ষ', 'ষাঁড়', '🐂'],
  ['স', 'সূর্য', '☀️'],
  ['হ', 'হাতি', '🐘'],
  ['ড়', 'বড়', '🌳'],
  ['ঢ়', 'আষাঢ়', '🌧️'],
  ['য়', 'সময়', '⏰'],
  ['ৎ', 'সৎ', '🤝'],
  ['ং', 'রং', '🎨'],
  ['ঃ', 'দুঃখ', '💙'],
  ['ঁ', 'চাঁদ', '🌙'],
];

class LearningBook extends ConsumerStatefulWidget {
  const LearningBook({super.key, required this.onLearn});
  final Future<void> Function(String id) onLearn;
  @override
  ConsumerState<LearningBook> createState() => _LearningBookState();
}

class _LearningBookState extends ConsumerState<LearningBook> {
  String _language = 'en';
  int _index = 0;
  bool _quiz = false;
  String? _feedback;
  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final letters = _language == 'bn' ? banglaAlphabet : englishAlphabet;
    final item = letters[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s['alphabet'], style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'bn', label: Text('বাংলা')),
          ],
          selected: {_language},
          onSelectionChanged: (v) => setState(() {
            _language = v.first;
            _index = 0;
            _feedback = null;
          }),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(s['letterQuiz']),
          value: _quiz,
          onChanged: (v) => setState(() {
            _quiz = v;
            _feedback = null;
          }),
        ),
        Card(
          color: const Color(0xffd4eff3),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    item[2],
                    key: ValueKey('$_language$_index'),
                    style: const TextStyle(fontSize: 90),
                  ),
                ),
                Text(
                  _quiz ? '?' : item[0],
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff174d73),
                  ),
                ),
                Text(item[1], style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(s['listen']),
          onPressed: () async {
            final available = await ref
                .read(launcherProvider)
                .speak(
                  _language == 'bn'
                      ? '${item[0]} দিয়ে ${item[1]}'
                      : '${item[0]} for ${item[1]}',
                  _language,
                );
            if (mounted && !available) {
              setState(() => _feedback = 'voiceMissing');
            }
          },
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(s[_feedback!]),
          ),
        if (_quiz)
          Wrap(
            spacing: 12,
            children: [
              for (final n in {
                _index,
                (_index + 5) % letters.length,
                (_index + 11) % letters.length,
              }.toList()..sort())
                OutlinedButton(
                  onPressed: () async {
                    if (n == _index) {
                      await widget.onLearn('alphabet:$_language:$_index');
                    }
                    if (mounted) {
                      setState(
                        () => _feedback = n == _index ? 'correct' : 'tryAgain',
                      );
                    }
                  },
                  child: Text(
                    letters[n][0],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _index == 0
                    ? null
                    : () => setState(() {
                        _index--;
                        _feedback = null;
                      }),
                child: Text(s['previous']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() {
                  _index = (_index + 1) % letters.length;
                  _feedback = null;
                }),
                child: Text(s['nextLesson']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(s['letterHelp']),
      ],
    );
  }
}

class StoryBook extends ConsumerStatefulWidget {
  const StoryBook({super.key});
  @override
  ConsumerState<StoryBook> createState() => _StoryBookState();
}

class _StoryBookState extends ConsumerState<StoryBook>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  int _page = 0;
  int _story = 0;
  String _language = 'en';
  String? _error;
  static const _english = [
    'Nila and the Little Seed',
    'Nila found a little seed beside the path. “What do you need?” she wondered. She made a small home for it in the soil.',
    'Every morning, Nila gave the seed a little water. She waited. A small green leaf appeared. Growing takes care and patience.',
    'A bird came to rest by the new plant. Nila shared the shade with her friend. Small acts of kindness can grow into something wonderful.',
  ];
  static const _bangla = [
    'নীলা ও ছোট্ট বীজ',
    'পথের পাশে নীলা একটি ছোট্ট বীজ পেল। সে ভাবল, “তোমার কী চাই?” মাটিতে বীজটির জন্য ছোট্ট একটি ঘর বানাল।',
    'প্রতিদিন সকালে নীলা একটু করে পানি দিল। অপেক্ষা করল। একদিন ছোট্ট সবুজ পাতা দেখা গেল। বেড়ে উঠতে যত্ন আর ধৈর্য লাগে।',
    'নতুন গাছের কাছে একটি পাখি এল। নীলা তার বন্ধুর সঙ্গে ছায়া ভাগ করে নিল। ছোট্ট ভালো কাজ থেকেও সুন্দর কিছু বড় হয়ে ওঠে।',
  ];
  static const moreEnglish = [
    [
      'Sami Shares the Rain',
      'Sami carried a bright umbrella. Raindrops tapped a little song. He saw his friend waiting beside a puddle.',
      '“There is room for two,” said Sami. They walked slowly, counting the drops on the leaves. One, two, three!',
      'The rain stopped. Sami and his friend found a rainbow. Sharing had made a grey afternoon feel bright.',
    ],
    [
      'The Shape Picnic',
      'Lina packed a picnic. Her plate was a circle. Her little box was a square. A folded napkin made a triangle.',
      'A bird watched from a branch. Lina pointed to shapes around the garden. A round flower! A square window!',
      'She drew the shapes in her notebook. Finding patterns made an ordinary picnic into a new adventure.',
    ],
    [
      'Rafi Takes a Quiet Moment',
      'Rafi wanted to finish his tower quickly. The blocks tumbled down. He felt upset and put his hands in his lap.',
      'Rafi took one slow breath, then another. He asked for help. Together, he and his sister started with a wider base.',
      'The tower stood tall. Rafi smiled. Taking a quiet moment had helped him try again with a fresh idea.',
    ],
  ];
  static const moreBangla = [
    [
      'সামির ছাতার নিচে',
      'সামির হাতে রঙিন ছাতা। টুপটাপ বৃষ্টি ছোট্ট গান গায়। এক বন্ধুকে সে পানির পাশে দাঁড়িয়ে থাকতে দেখল।',
      'সামি বলল, “দুজনেরই জায়গা হবে!” তারা আস্তে হাঁটল। পাতার ফোঁটা গুনল—এক, দুই, তিন!',
      'বৃষ্টি থামল। বন্ধুরা রংধনু দেখল। একসঙ্গে ভাগ করে নেওয়ায় মেঘলা বিকেলও সুন্দর হয়ে উঠল।',
    ],
    [
      'আকারের বনভোজন',
      'লীনা বনভোজনে গেল। তার থালা গোল। ছোট্ট বাক্সটি চৌকো। ভাঁজ করা রুমাল ত্রিভুজের মতো।',
      'ডালে একটি পাখি বসে ছিল। লীনা বাগানে আরও আকার খুঁজল। গোল ফুল! চৌকো জানালা!',
      'খাতায় সে আকারগুলো আঁকল। চেনা জিনিসের মধ্যে নকশা খুঁজে সাধারণ বনভোজনও নতুন অভিযানে বদলে গেল।',
    ],
    [
      'রাফির শান্ত মুহূর্ত',
      'রাফি তাড়াতাড়ি ব্লক দিয়ে মিনার বানাতে চাইল। ব্লকগুলো পড়ে গেল। মন খারাপ হলো। কোলে হাত রেখে সে একটু বসল।',
      'রাফি ধীরে শ্বাস নিল। আবার নিল। তারপর সাহায্য চাইল। বোনকে নিয়ে এবার মিনারের নিচটা আরও চওড়া করল।',
      'মিনারটি দাঁড়িয়ে রইল। রাফি হাসল। একটু শান্ত হয়ে ভাবায় নতুন বুদ্ধি নিয়ে আবার চেষ্টা করা গেল।',
    ],
  ];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final stories = _language == 'bn'
        ? [_bangla, ...moreBangla]
        : [_english, ...moreEnglish];
    final pages = stories[_story];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s['stories'], style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'bn', label: Text('বাংলা')),
          ],
          selected: {_language},
          onSelectionChanged: (v) => setState(() => _language = v.first),
        ),
        DropdownButton<int>(
          isExpanded: true,
          value: _story,
          items: [
            for (var i = 0; i < stories.length; i++)
              DropdownMenuItem(value: i, child: Text(stories[i][0])),
          ],
          onChanged: (v) => setState(() {
            _story = v ?? 0;
            _page = 0;
          }),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => AspectRatio(
            aspectRatio: 1.3,
            child: CustomPaint(
              painter: GardenPainter(_page, _animation.value, theme: _story),
            ),
          ),
        ),
        Text(pages[0], style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            pages[_page + 1],
            key: ValueKey('$_page$_language'),
            style: const TextStyle(fontSize: 23, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final ok = await ref
                .read(launcherProvider)
                .speak(pages[_page + 1], _language);
            if (mounted) setState(() => _error = ok ? null : 'voiceMissing');
          },
          icon: const Icon(Icons.volume_up),
          label: Text(s['listen']),
        ),
        if (_error != null) Text(s[_error!]),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _page == 0 ? null : () => setState(() => _page--),
                child: Text(s['previous']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _page == 2 ? null : () => setState(() => _page++),
                child: Text(s['nextLesson']),
              ),
            ),
          ],
        ),
        Text(s['originalStory']),
      ],
    );
  }
}

class GardenPainter extends CustomPainter {
  GardenPainter(this.page, this.motion, {this.theme = 0});
  final int theme;
  final int page;
  final double motion;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      paint..color = const Color(0xffd4eff3),
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .18),
      size.width * .075,
      paint..color = const Color(0xffffce66),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .76, size.width, size.height * .24),
      paint..color = const Color(0xffb9dba9),
    );
    if (theme == 1) {
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(
            size.width * (.45 + i * .05),
            size.height * (.2 + ((motion + i * .2) % 1) * .4),
          ),
          3,
          paint..color = const Color(0xff174d73),
        );
      }
    }
    if (theme == 2) {
      canvas.drawCircle(
        Offset(size.width * .75, size.height * .4),
        22,
        paint..color = const Color(0xffffb95a),
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * .6, size.height * .52, 36, 36),
        paint..color = const Color(0xff7057a3),
      );
    }
    final x = size.width * .56, y = size.height * .77;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 60, height: 16),
      paint..color = const Color(0xff926447),
    );
    if (page > 0) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x + motion * 4, y - size.height * .33),
        paint
          ..color = const Color(0xff267144)
          ..strokeWidth = 8,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 18, y - size.height * .22),
          width: 48,
          height: 24,
        ),
        paint..color = const Color(0xff43a36c),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 23, y - size.height * .31),
          width: 52,
          height: 26,
        ),
        paint,
      );
    }
    // Nila: an original geometric story character, no external image assets.
    canvas.drawCircle(
      Offset(size.width * .24, size.height * .38),
      size.width * .07,
      paint..color = const Color(0xffce916b),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .17,
          size.height * .48,
          size.width * .14,
          size.height * .25,
        ),
        const Radius.circular(16),
      ),
      paint..color = const Color(0xff7057a3),
    );
    for (final dx in [.215, .265]) {
      canvas.drawCircle(
        Offset(size.width * dx, size.height * .375),
        3,
        paint..color = const Color(0xff203b52),
      );
    }
    if (page == 2) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .75, size.height * (.54 + motion * .02)),
          width: 45,
          height: 27,
        ),
        paint..color = const Color(0xff174d73),
      );
      final path = Path()
        ..moveTo(size.width * .79, size.height * .53)
        ..lineTo(size.width * .84, size.height * .55)
        ..lineTo(size.width * .79, size.height * .57)
        ..close();
      canvas.drawPath(path, paint..color = const Color(0xffffb95a));
    }
  }

  @override
  bool shouldRepaint(covariant GardenPainter oldDelegate) =>
      oldDelegate.page != page ||
      oldDelegate.motion != motion ||
      oldDelegate.theme != theme;
}
