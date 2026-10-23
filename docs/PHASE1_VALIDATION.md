# Phase 1 validation — 22 October 2026

This report covers the current cloud instance. It is not a physical-device,
Play Store, Firebase, production-readiness or new-task restoration certification.

| Check | Observed outcome |
| --- | --- |
| Frozen installation | `flutter pub get --enforce-lockfile` passed |
| Format | `dart format --output=none --set-exit-if-changed lib test` passed |
| Static analysis | `flutter analyze` passed with no issues |
| Automated tests | `flutter test --reporter expanded`: 21 passed; no failed or skipped tests |
| Android build | `flutter build apk --debug --target-platform android-arm64` passed |
| Android lint | `./android/gradlew -p android :app:lintDebug -Ptarget-platform=android-arm64` passed; report says No issues found |
| Signature | `apksigner verify --verbose`: valid v2 debug signature, one signer |
| APK metadata | `com.kidsafe.launcher`, version 0.1.0+1, min API 26, target/compile API 36, ARM64 only |
| Repeatability | Revised `bash tool/cloud-install.sh` completed and rebuilt the APK successfully against retained tools/caches |
| Localization | All 65 translation keys exist in both English and Arabic; RTL and numeral input covered by widgets |
| XML | All project Android XML resources parsed; Android resource/manifest compilation passed |

Test breakdown: 12 domain/policy tests, 2 real PBKDF2 tests, 2 native-vault
adapter tests and 5 widget tests. Widgets cover consent and initial PIN setup,
parent/child routing, parent-only exit, relocking sensitive screens, pending
unlock races and Arabic RTL. Tests use in-memory persistence for policy tests
and mocked method channels for UI/adapter tests. They do not exercise Android
Keystore, filesystem durability or actual permission dialogs.

The native encrypted vault, permission adapters, launcher, receiver and
Accessibility service compiled successfully. Their runtime/OEM behavior still
needs the real-device checks in DEVICE_TESTS.md. There is no connected emulator
or phone, and this cloud machine has no `/dev/kvm` acceleration device.

Toolchain used: Flutter 3.35.7 / Dart 3.9.2, Temurin JDK 21.0.12.1+1,
Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, Android SDK 36, build tools 35.0.0,
NDK 27.0.12077973 and CMake 3.22.1. The Gradle wrapper, distribution,
JDK and Android command-line archive were checksum verified against official
HTTPS sources. The environment proxy and administered certificate trust store
were configured without disabling TLS verification.

Nonfatal tooling notices: SDK Manager delegates to Google's newer Android CLI;
Gradle reports deprecated features ahead of Gradle 9. Keep the tested pin until
an intentional upgrade is validated. Latest SDK metadata also produced an
XML-version compatibility warning during the initial build; compilation passed.

APK: `build/app/outputs/flutter-apk/app-debug.apk`

SHA-256: `d151e12df0e9e6c0ee94d2e474c9de2327a539881603ca927bbc826c03bfcabd`

This artifact is debug signed and for testing only. Firebase initialization,
family rules, FCM, remote pairing, tasks, points/rewards, videos and app blocking
are not implemented or validated in this phase. The Firebase baseline denies
all clients and has not been deployed. Physical-device results, signed release
builds and Play policy acceptance are unrun. Source was created locally; no
GitHub push or Store publication was performed.
