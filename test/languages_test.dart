import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/l10n/strings.dart';
import 'package:kidsafe_launcher/l10n/learning_strings.dart';
import 'package:kidsafe_launcher/features/access/presentation/pin_form.dart';
import 'package:kidsafe_launcher/features/learning/presentation/learning_book.dart';

void main() {
  test('every learning label has English, Arabic and Bangla text', () {
    for (final entry in learningStrings.entries) {
      expect(entry.value.length, 3, reason: entry.key);
      for (final value in entry.value) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });
  test('Bangla covers all first-run, PIN, permission and privacy flows', () {
    const bn = Strings(false, bangla: true);
    for (final key in [
      'app',
      'welcome',
      'consent',
      'begin',
      'enterPin',
      'unlock',
      'wrong',
      'locked',
      'storage',
      'choosePins',
      'newParent',
      'newKid',
      'permissions',
      'home',
      'admin',
      'accessibility',
      'overlay',
      'usage',
      'privacyBody',
      'tasks',
      'rewards',
      'videos',
    ]) {
      expect(bn[key], isNot(key));
      expect(bn[key], matches(RegExp('[\u0980-\u09ff]')));
    }
  });
  test('PIN input accepts Bangla, Arabic, Persian and ASCII digits', () {
    expect(normalizePin('১০২০'), '1020');
    expect(normalizePin('٧٢٩٣٨٤'), '729384');
    expect(normalizePin('۷۲۹۳۸۴'), '729384');
    expect(normalizePin('1234'), '1234');
  });
  test('alphabet book contains all English letters and Bangla vowels', () {
    expect(
      englishAlphabet.map((r) => r[0]).join(),
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );
    expect(banglaAlphabet.take(11).map((r) => r[0]).join(), 'অআইঈউঊঋএঐওঔ');
    for (final row in [...englishAlphabet, ...banglaAlphabet]) {
      expect(row.length, 3);
      expect(row[1], isNotEmpty);
    }
  });
}
