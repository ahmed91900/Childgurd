# v0.2 beta validation — 23 October 2026

Results from this cloud workspace. These are not phone/OEM tests or a claim that production Firebase is deployed.

| Check | Observed result |
| --- | --- |
| Dart format | 25 files, zero changes needed |
| Flutter analysis | No issues found |
| Flutter unit/widget suite | **51 passed** |
| Firebase emulator suite | **26 passed**: 14 Firestore rules, 8 callable integrations, 4 Storage rules |
| Backend production dependency audit | Zero reported vulnerabilities with pinned firebase-admin 14.5.0 / firebase-functions 7.4.0 at this check |
| ARM64 Android build | Debug APK built successfully, version 0.2.1 / code 3 |
| Android app lint | BUILD SUCCESSFUL; zero errors, eight advisory warnings (synchronous SharedPreferences writes and KTX style) |
| APK signature | apksigner verified APK v2 signature; Android Debug certificate |
| Package/platform | com.kidsafe.launcher; min API 26, compile/target API 36; arm64-v8a |
| Source whitespace | git diff --check passed |

## Covered behavior

PIN tests exercise real PBKDF2 hashing, independent salts, malformed records, wrong PINs, parent-only routes, mandatory default replacement, profile PIN uniqueness/persistence, shared five-attempt lockout across service restarts, clock rollback and failed durable writes. Widget tests cover setup/route/lifecycle behavior, Arabic RTL and numeric input. Native vault operations are mocked in Flutter tests.

Task/model tests cover canonical reward values, duplicate completion, disabled/scheduled/child-scoped assignments, task gates, daily/weekly limits, more-time decisions/deduplication/expiry, serialization, failed writes and queued local/remote updates. Offline outbox tests verify restart persistence, no sync echo, retention without losing all-time points, and family-data clearing on account changes. Activity widgets exercise correct/incorrect math, Bengali digits and persisted drawing gestures. Localization tests cover three-language learning labels, Bangla core screens, numeral normalization and alphabet data.

Firebase emulators exercised real callable handlers against emulated Auth/Firestore: parent registration, short-lived single-use pairing, replacement revocation, five-attempt rate limits, owner-only global ad toggle, revoked-device push registration and family/account deletion. Rules tests cover cross-family/unauthenticated denial, scoped device reads, immutable links, bounded monotonic progress and owner-only MIME/size-bounded media uploads/deletion.

FCM delivery is deliberately disabled inside emulator tests. Video decoding, Android TTS voices, file picker, Firebase Storage Android upload and full client-to-live-backend sync are not end-to-end tested by these server tests.

## Toolchain and resolved build issue

Flutter 3.35.7 / Dart 3.9.2, Temurin JDK 21, Android SDK 36, AGP 8.9.1, Kotlin 2.1.0, Gradle 8.12 and Node 22.23.4. The modern AndroidX plugins do not need legacy Jetifier; it is disabled because it could not parse a newer Byte Buddy test jar. The rebuilt APK and lint succeeded with AndroidX directly. The eight app lint warnings recommend asynchronous SharedPreferences writes and Kotlin extension style. Policy flags are synchronously committed so an app return cannot race a delayed blocking-state write; those advisories were retained rather than suppressed. Third-party Java-8 deprecation, Gradle-next-major and sandbox metrics notices also appeared.

## Not yet validated or activated

No physical phone, emulator UI or /dev/kvm was available. The [device matrix](DEVICE_TESTS.md) remains required: OEM app-redirection races/escape paths, real Keystore/power loss, permission revocation/reboot, offline voice availability, audio quality, video/network behavior, low-end hashing, battery impact, accessibility/text scaling, remote phone pairing, live push delivery and owner ad rollout.

The public beta is debug signed and contains no production Firebase project or AdMob application ID. Offline learning/local controls are available; separate-phone sync and owner ad controls require the operator's configured build and deployed backend. There is no Play submission, Store policy approval, legal certification or production-protection guarantee. Use only under parent supervision with non-sensitive test data.

See [Firebase setup](FIREBASE_SETUP.md), [security boundaries](SECURITY.md) and [Play release checklist](PLAY_RELEASE_CHECKLIST.md). The separate Phase 1 report is historical evidence, not the current feature list.

The v0.2.1 patch normalizes both a guardian's custom answer and the child's entry, including Bangla/Arabic/Persian numerals. Three regression cases reject a wrong answer and accept the matching value across scripts.
