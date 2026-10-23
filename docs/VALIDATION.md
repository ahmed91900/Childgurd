# v0.2 beta validation — 23 October 2026

Results from this cloud workspace. These are not phone/OEM tests or a claim that production Firebase is deployed.

| Check | Observed result |
| --- | --- |
| Dart format | 27 files, zero changes needed |
| Flutter analysis | No issues found |
| Flutter unit/widget suite | **59 passed** |
| Firebase emulator suite | **30 passed**: 17 Firestore rules, 9 callable integrations, 4 Storage rules |
| Backend production dependency audit | Zero reported vulnerabilities with pinned firebase-admin 14.5.0 / firebase-functions 7.4.0 at this check |
| Universal Android build | Debug APK built successfully, version 0.2.3 / code 5; three CPU architectures included |
| Android app lint | BUILD SUCCESSFUL; zero errors, eight advisory warnings (synchronous SharedPreferences writes and KTX style) |
| APK signature | apksigner verified APK v2 signature; Android Debug certificate |
| Package/platform | com.kidsafe.launcher; min API 24, compile/target API 36; armeabi-v7a, arm64-v8a and x86_64 |
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

## v0.2.2 compatibility expansion

The compatibility target is now Android 7.0+ on ARM32, ARM64 and x86-64. Android 6 and earlier are excluded by the current video-player plugin. iOS cannot run this Android APK/launcher model. `tool/verify_apk.py` checks the actual packaged ELF engines, minimum SDK, ZIP integrity and APK signature; packaging validation is distinct from executing the app on each architecture. No Android 7 phone, 32-bit device or x86-64 emulator has been runtime tested in this workspace.

Workspace validation passed for v0.2.2: 51 Flutter tests, no Dart analysis findings, a universal Android build, signature verification and Android lint (zero errors/eight existing preference/style advisories). The packaging gate accepted all three correct ELF engines and API 24, and rejected the earlier ARM64-only APK. That compatibility build used the earlier 26-test backend suite. The current 30-test suite includes the additional v0.2.3 Google/backup cases below.

## v0.2.3 setup and backup checks

59 Flutter tests pass, including exactly two first-run PIN fields, small-screen show/hide controls, separate parent reauthentication for changes, and six learning-backup tests covering restore, metadata exclusion, idempotency, preservation of newer progress, invalid/oversized records and failed durable writes. Native child-mode dispatch is checked through the mocked method channel.

30 backend tests pass, including verified Google-provider backup access, child/cross-family denial, schema/type/size checks, and an actual emulated Google credential signing in, registering a parent, saving/recovering a private backup and deleting the family/backup. Emulator fake Google tokens never contact production. This does not exercise the real Android Google account chooser.

Dart analysis has no issues. The universal API-24 APK, ELF/signature verification and Android lint succeeded locally. Firebase/Google public configuration is absent in the released offline beta. Google sign-in, live backup/recovery, account selection cancellation, OAuth/signing configuration and OEM behavior need real devices and a test Firebase project before production claims.

An explicitly empty `ADMOB_APP_ID` was built and inspected successfully. Gradle now treats blank/omitted IDs alike, retaining the official test application ID required by the ads SDK while live ads remain disabled. The packaging gate checks the actual merged manifest ID; CI builds this blank-ID case as a regression check.
