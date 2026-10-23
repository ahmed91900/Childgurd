import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsafe_launcher/core/providers.dart';
import 'package:kidsafe_launcher/features/access/domain/access_service.dart';
import 'package:kidsafe_launcher/features/access/presentation/pin_form.dart';
import 'package:kidsafe_launcher/main.dart';
import 'package:kidsafe_launcher/features/family/data/family_repository.dart';

import 'access_service_test.dart' show MemoryVault, FakeHasher;

class PausableHasher extends FakeHasher {
  Completer<void>? gate;
  @override
  Future<bool> verify(String pin, String encoded) async {
    await gate?.future;
    return super.verify(pin, encoded);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kidsafe.launcher/device');
  late AccessService access;

  setUp(() async {
    access = AccessService(MemoryVault(), FakeHasher());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'status':
              return {
                'home': false,
                'admin': false,
                'accessibility': false,
                'overlay': false,
                'usage': false,
              };
            case 'apps':
              return [
                {'label': 'Calculator', 'package': 'example.calculator'},
              ];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final family = FamilyRepository(MemoryVault());
    await family.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessProvider.overrideWithValue(access),
          familyProvider.overrideWith((ref) => family),
        ],
        child: const KidSafeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> configured() async {
    await access.load();
    await access.changePins(
      currentParent: '1020',
      parent: '729384',
      kid: '458291',
    );
  }

  Future<void> enter(WidgetTester tester, String pin) async {
    await tester.enterText(find.byType(TextField).first, pin);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
  }

  testWidgets('first run requires consent and both new PINs', (tester) async {
    await mount(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Set up this phone'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up this phone'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    for (var i = 0; i < 5; i++) {
      await tester.enterText(
        fields.at(i),
        ['1020', '729384', '729384', '458291', '458291'][i],
      );
    }
    await tester.ensureVisible(find.text('Save private PINs'));
    await tester.tap(find.text('Save private PINs'));
    await tester.pumpAndSettle();
    expect(access.configured, true);
    expect(find.text('Prepare this Android phone'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('child mode exit rejects child PIN and allows parent PIN', (
    tester,
  ) async {
    await configured();
    await mount(tester);
    await enter(tester, '458291');
    expect(find.text('Today’s Tasks'), findsOneWidget);
    expect(find.text('Calculator'), findsNothing);
    await tester.ensureVisible(find.text('Parent access'));
    await tester.tap(find.text('Parent access'));
    await tester.pumpAndSettle();
    await enter(tester, '458291');
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
    await enter(tester, '729384');
    expect(find.text('Calculator'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('backgrounding removes sensitive screens and parent access', (
    tester,
  ) async {
    await configured();
    await mount(tester);
    await enter(tester, '729384');
    await tester.tap(find.text('Change PINs'));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsNothing);
    expect(find.text('Unlock'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Arabic uses RTL and Arabic numerals normalize to ASCII', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    final text = find.text('بداية أكثر أماناً، معاً');
    expect(text, findsOneWidget);
    expect(Directionality.of(tester.element(text)), TextDirection.rtl);
    expect(normalizePin('٧٢٩٣٨٤'), '729384');
    expect(normalizePin('۷۲۹۳۸۴'), '729384');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'an unlock finishing after backgrounding cannot restore parent mode',
    (tester) async {
      final hasher = PausableHasher();
      access = AccessService(MemoryVault(), hasher);
      await configured();
      await mount(tester);
      hasher.gate = Completer<void>();
      await tester.enterText(find.byType(TextField).first, '729384');
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      hasher.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Calculator'), findsNothing);
      expect(find.text('Parent space'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
