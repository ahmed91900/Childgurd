<p align="center"><img src="docs/assets/kidsafe-banner.svg" alt="KidSafe Launcher — a thoughtful start for family screen time" width="100%" /></p>
<p align="center"><strong>An offline learning space with a private parent dashboard.</strong><br />Flutter · Kotlin · English · বাংলা · العربية</p>
<p align="center"><a href="https://github.com/ahmed91900/Childgurd/releases/tag/v0.2.3-beta.1">Download Android beta</a> · <a href="docs/GETTING_STARTED.md">First-run guide</a> · <a href="docs/VALIDATION.md">Test results</a> · <a href="docs/RESEARCH.md">61-repository review</a></p>

## Learn, play, and grow together

KidSafe Launcher gives children original learning activities instead of an open social-media feed. A parent PIN opens the family dashboard and the phone's app list; each child PIN opens a learning space. Local learning and same-phone parental controls work without an account or internet connection.

**v0.2 is an installable development beta for supervised testing, not a Play Store production release.** The universal APK targets Android 7.0 and later, with 32-bit ARM, 64-bit ARM and x86-64 included. It is debug signed. Separate-phone control and owner-managed advertising are implemented in source and tested against Firebase emulators, but are **not activated in this APK**: no production Firebase project, Google OAuth client or advertising account was supplied. Google backup is also unavailable in this public build until that setup is supplied. See [Firebase setup](docs/FIREBASE_SETUP.md).

## What's inside

| Feature | Current behavior |
| --- | --- |
| Offline learning | Math, reading, memory, number patterns, drawing, English vocabulary, spelling, counting and shapes; age and difficulty settings |
| Speaking alphabet book | 26 English letters and 50 Bangla letters/signs with words, visual cues and matching quizzes; uses installed offline Android voices |
| Original animated stories | Four stories in English and Bangla, geometric illustrations, page controls and optional narration; no autoplay |
| Rewards | Idempotent task completion, points, stars and parent-defined task gates |
| Family dashboard | Up to eight local child profiles, individual PINs, today's/week's progress, custom scheduled tasks and per-child library switches |
| Screen-time controls | Foreground play/story/video allowance, task-before-play gate, request-more-time and parent decisions |
| Parent-approved media | Direct HTTPS MP4 links only, deliberate playback; no browser, public feed, Shorts, comments or looping |
| Google-linked backup | Optional Google sign-in, private learning backup and automatic restore on a fresh phone; requires Firebase/Google setup; PINs stay local |
| PIN protection | Salted PBKDF2 hashes, Android Keystore AES-GCM vaults, mandatory default-PIN replacement, persistent five-attempt lockout |
| Android setup | Home selection, Device Admin and Accessibility guidance, permission-revocation warning, optional overlay/usage status |
| Separate parent phone | Verified parent Auth, one-time anonymous child-device pairing, Firestore assignment/progress sync, persistent offline outbox and backend FCM hints; requires deployment |
| Owner-controlled ads | Off by default; owner claim controls global on/off and AdMob/image/video settings; each guardian must also opt their child in; requires deployment |
| Languages | English, Bangla and Arabic UI; Arabic RTL; Bengali/Arabic/Persian PIN digits |

Audio needs an installed **offline** voice for the chosen language. The app explains unavailable voices rather than sending child speech to a network engine. Direct online video and advertisements need internet; lessons, stories, drawings and local progress do not. This version does not download videos for offline playback.

## Install and try it

1. Open the [beta release](https://github.com/ahmed91900/Childgurd/releases/tag/v0.2.3-beta.1) on an Android 7.0+ phone and download `KidSafe-Launcher-universal-beta.apk` from **Assets**.
2. Open the downloaded APK and allow installation from that source when Android asks. Read the beta limitations before enabling launcher permissions.
3. Choose English or বাংলা, read parental consent/privacy, then set **Parent PIN** and **Kids PIN**. There are only two fields; use the eye icons to check what you typed. Choose different PINs of 4–12 digits.
4. Follow the permission guide. Enter the new parent PIN when returning from Android settings.
5. Use the parent dashboard to set the child's age, activities and allowance. Lock the launcher and enter the child PIN to learn.

No ADB, Device Owner enrollment, Firebase account or ads are required for this offline workflow. Keep another known launcher installed while testing. [Detailed setup and recovery](docs/GETTING_STARTED.md).

## Build and verify

Flutter **3.35.7**, JDK **21**, Android SDK **36**, min SDK **24**, Node **22** for backend tests.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
python3 tool/verify_apk.py build/app/outputs/flutter-apk/app-debug.apk
./android/gradlew -p android :app:lintDebug -Ptarget-platform=android-arm,android-arm64,android-x64
```

Backend setup, emulator commands and production build configuration: [Firebase guide](docs/FIREBASE_SETUP.md). Complete file contents are downloadable as `FULL_SOURCE.md` and a source ZIP in the release; regenerate with `python3 tool/export_source.py`.

## Structure

```text
lib/core/                   Riverpod dependency injection
lib/features/access/        PIN domain, encrypted storage adapter, lock and parent shell
lib/features/setup/         Android permission adapter and consent wizard
lib/features/family/        Offline model, serialized repository and family dashboard
lib/features/learning/      Activities, alphabet book, original stories and media player
lib/features/cloud/         Scoped Firebase sync, parent pairing and owner ads
lib/l10n/                   English, Bangla and Arabic
android/                    Kotlin vaults, launcher boundary, offline TTS and Accessibility
firebase/                   Firestore/Storage rules, trusted functions and 30 emulator tests
test/                       59 Flutter unit/widget tests
```

## Honest protection boundaries

Accessibility tries to return Home when an unapproved app opens. It cannot guarantee containment of Android settings, recents, notifications, safe mode, permission revocation, uninstall or factory reset. Device Admin can be deactivated. This app does not replace Android's system lock, provide device-wide adult-content filtering, inspect YouTube channels, or promise that permission grants make every feature infallible. Parents must review every approved media source and supervise beta use. App time limits cover KidSafe's play/media surfaces, not all phone usage or open learning exercises.

Read [security/privacy boundaries](docs/SECURITY.md), [physical-device tests](docs/DEVICE_TESTS.md), [release checklist](docs/PLAY_RELEASE_CHECKLIST.md), [research and licenses](docs/RESEARCH.md), and [remaining release work](docs/ROADMAP.md).

Built by [Mohammed Alamin](https://github.com/extramail9922-alt).

## Phone compatibility

| Device | Compatibility target |
| --- | --- |
| Android 7.0+ with 32-bit ARM, 64-bit ARM or x86-64 | Included in the universal APK; physical-device testing remains required |
| Android 6 and earlier, or 32-bit x86 | Unsupported by the current plugin/Flutter combination |
| iPhone/iPad | APKs cannot install; iOS does not support this Android launcher/Accessibility model |
| Android devices without Google Play services | Offline lessons are designed to work independently; cloud push/Google ads require compatible services and device testing |

This is broader packaging support, not a claim that every phone has been tested. Some manufacturers restrict Home selection, Accessibility, Device Admin, background execution or offline voice installation. The universal APK is larger because it contains three CPU architectures.
