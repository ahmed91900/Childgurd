import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/features/learning/presentation/activity.dart';
import 'package:kidsafe_launcher/features/family/domain/family.dart';

void main() {
  testWidgets(
    'math gives feedback and persists a reward only for a correct answer',
    (tester) async {
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Activity(
                task: const LearningTask(id: 'library:math', kind: 'math'),
                child: ChildProfile(id: 'child'),
                onComplete: (_) async {
                  completions++;
                },
              ),
            ),
          ),
        ),
      );
      final prompt = tester
          .widget<Text>(find.textContaining(RegExp(r'^\d+ \+ \d+ = \?$')))
          .data!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(prompt).map((m) => int.parse(m[0]!)).toList();
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(completions, 0);
      expect(find.text('Keep trying. You can do it!'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        '${numbers[0] + numbers[1]}',
      );
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(find.text('Great work! You earned your stars.'), findsOneWidget);
      expect(find.text('Check answer'), findsNothing);
    },
  );

  testWidgets('Bangla arithmetic accepts Bengali digits', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        supportedLocales: const [Locale('bn'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Activity(
              task: const LearningTask(id: 'library:math', kind: 'math'),
              child: ChildProfile(id: 'child'),
              onComplete: (_) async {
                saved = true;
              },
            ),
          ),
        ),
      ),
    );
    final text = tester
        .widget<Text>(find.textContaining(RegExp(r'^\d+ \+ \d+ = \?$')))
        .data!;
    final n = RegExp(
      r'\d+',
    ).allMatches(text).map((m) => int.parse(m[0]!)).toList();
    final answer = '${n[0] + n[1]}'
        .split('')
        .map((c) => String.fromCharCode(0x9e6 + int.parse(c)))
        .join();
    await tester.enterText(find.byType(TextField), answer);
    await tester.tap(find.text('উত্তর যাচাই'));
    await tester.pumpAndSettle();
    expect(saved, true);
    expect(find.text('দারুণ! তুমি তারা পেয়েছ।'), findsOneWidget);
  });

  testWidgets('drawing requires a real gesture and returns saved stroke data', (
    tester,
  ) async {
    List<List<Offset>>? stored;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Activity(
              task: const LearningTask(id: 'library:drawing', kind: 'drawing'),
              child: ChildProfile(id: 'child'),
              onComplete: (s) async {
                stored = s;
              },
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Save my drawing'));
    await tester.tap(find.text('Save my drawing'));
    await tester.pumpAndSettle();
    expect(stored, isNull);
    final canvas = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DrawingPainter,
    );
    await tester.ensureVisible(canvas);
    final rect = tester.getRect(canvas);
    for (var i = 0; i < 3; i++) {
      final gesture = await tester.startGesture(
        rect.topLeft + Offset(30, 30 + i * 30),
      );
      for (var j = 0; j < 5; j++) {
        await gesture.moveBy(const Offset(12, 3));
        await tester.pump();
      }
      await gesture.up();
    }
    await tester.ensureVisible(find.text('Save my drawing'));
    await tester.tap(find.text('Save my drawing'));
    await tester.pumpAndSettle();
    expect(stored, isNotNull);
    expect(stored!.length, 3);
    expect(stored!.every((stroke) => stroke.length >= 2), true);
  });
  for (final pair in [
    ['৫', '5'],
    ['৫', '৫'],
    ['۵', '٥'],
  ]) {
    testWidgets('custom numeric answer ${pair[0]} accepts input ${pair[1]}', (
      tester,
    ) async {
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Activity(
                task: LearningTask(
                  id: 'custom:sum',
                  kind: 'custom',
                  prompt: '2 + 3 = ?',
                  answer: pair[0],
                ),
                child: ChildProfile(id: 'child'),
                onComplete: (_) async {
                  completions++;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '4');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(completions, 0);
      await tester.enterText(find.byType(TextField), pair[1]);
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(completions, 1);
    });
  }
}
