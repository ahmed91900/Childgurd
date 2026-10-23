# Development and first-run setup

Android-only Flutter foundation for a parent-controlled launcher. This phase is
**not ready for unsupervised child protection or Play Store release**. It does not
yet restrict other apps. No ADB or Device Owner enrollment is needed by parents.
Developer build/install tooling is separate from the parent's setup workflow.

## Implemented

- First-run guardian consent and privacy/Android-limit disclosures.
- Mandatory replacement of **both** bootstrap PINs: parent `1020`, child `0000`.
  Neither default may be reused for either role. PINs must differ and contain
  4–12 digits. Arabic and Persian numerals normalize to ASCII.
- PBKDF2-HMAC-SHA256, 210,000 iterations, independent cryptographically random
  128-bit salts, 256-bit outputs, fixed-length comparison. Hashing runs off the
  UI isolate. PINs are never logged or sent to a server.
- AES-256-GCM encrypted storage with a non-exportable Android Keystore key.
  Credential and retry state share one atomically written, disk-synced record.
- Five wrong attempts cause a five-minute lockout, including during initial setup
  and credential changes. Counters/deadlines persist across process restarts.
- Parent PIN opens an installed-app list. Child PIN opens the original four-card
  Kids Mode foundation. Child PIN cannot authorize a Kids Mode exit or PIN change.
- Default Home, Device Admin, Accessibility, overlay and Usage Access settings
  links, real status checks, foreground polling, and refresh on resume.
- Parent sessions relock on focus loss or backgrounding. Screenshots/recents thumbnails are
  protected using `FLAG_SECURE`. Android cloud backup/device transfer are disabled.
- English/Arabic, automatic system locale selection, explicit language switch,
  RTL, scalable text, scrollable layouts and large primary touch targets.

The task/video/game/reward cards deliberately say **Coming in a later phase**.
Accessibility is a status-only service; it collects no screen content and blocks
no apps. Usage history and overlays are not consumed yet. Grants do not activate
features that have not been built.

## Structure

```text
lib/
  main.dart                              # Composition root and theme
  core/providers.dart                    # Riverpod dependency injection
  l10n/strings.dart                       # Complete English and Arabic strings
  features/access/
    domain/access_service.dart           # Pure Dart PIN/lockout policy
    data/secure_access.dart              # PBKDF2 and native vault adapters
    presentation/launcher_shell.dart     # Session lifecycle and mode routing
    presentation/pin_form.dart           # PIN entry, replacement and normalization
  features/setup/
    data/android_launcher.dart           # Typed method-channel boundary
    presentation/permission_wizard.dart   # Permission/status wizard
android/                                 # Kotlin launcher/permission adapters
test/                                    # Domain, real crypto and widget tests
docs/                                    # Security, device checks and release guide
tool/                                    # Cloud tooling and full-source export
```

## Build on your own computer

1. Install Flutter **3.35.7** (Dart **3.9.2**), Git, Android Studio and JDK 17 or
   21. This SDK pin is intentional; upgrade it in a separately tested change.
2. In Android Studio's SDK Manager install Android API **36**, build tools
   **35.0.0**, command-line tools and platform tools. Gradle may request an NDK
   or CMake version used by plugins; let the official SDK Manager install it.
3. Run `flutter doctor -v` and accept the Android SDK licenses after reviewing
   Google's terms: `flutter doctor --android-licenses`.
4. In the repository root:

   ```sh
   flutter pub get --enforce-lockfile
   flutter analyze
   flutter test --reporter expanded
   flutter build apk --debug --target-platform android-arm64
   ```

5. Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`. Use Android Studio
   or transfer this APK to your test phone and approve the install. A physical
   phone does not need ADB or Device Owner enrollment to use the setup wizard.
   Do not distribute a debug build as a production release.
6. For a developer-connected phone/emulator, `flutter run` is also supported.
   API 26 is the minimum supported OS; the supplied APK targets ARM64. Omit
   `--target-platform` for Flutter's default multi-ABI debug build.

`android/local.properties` is generated locally; never commit SDK paths or keys.
The Gradle distribution has a pinned SHA-256. Release signing is intentionally
absent. No release build uses debug signing credentials.

## In this cloud environment

Use the existing isolated checkout; do not create a Git worktree.

```sh
cd /workspace/Childgurd
source tool/cloud-env.sh
flutter analyze
flutter test --reporter expanded
flutter build apk --debug --target-platform android-arm64
```

`bash tool/cloud-install.sh` refreshes the pinned dependencies and tooling. The
script uses only official HTTPS sources, verifies downloaded checksums and keeps
caches under `/workspace`. Java networking uses the existing platform proxy, not
embedded credentials. Internet destinations needed: `github.com`,
`raw.githubusercontent.com`, `release-assets.githubusercontent.com`, `pub.dev`,
`storage.googleapis.com`, `services.gradle.org`, `downloads.gradle.org`,
`plugins.gradle.org`, `plugins-artifacts.gradle.org`, `repo.maven.apache.org`,
`dl.google.com` and `maven.google.com` (if a redirect uses it).

Some Dart tools also write fixed home paths `.dart-tool` and `.dartServer`;
the Android debug signer may use `.android`. These are local development state,
not app data. No phone or emulator is assumed to be connected to the cloud.

## First-run guide

1. Read **Privacy & Android limits**. Confirm that you are the guardian and
   consent to local credential storage. This checkbox is a local disclosure,
   not legally verified parental identity or a compliance certification.
2. Enter current parent PIN `1020`. Set and confirm a new parent PIN and a
   different new child PIN. Both defaults must be replaced. Prefer 6–12 digits.
   The initial child PIN `0000` cannot unlock modes during first setup.
3. Open each Android permission screen from the wizard. Choose KidSafe as Home;
   activate Device Admin; review the Accessibility disclosure before enabling;
   grant overlay and Usage Access. Names/locations differ across OEMs.
4. Returning from a settings screen relocks the launcher. Enter the **new**
   parent PIN, open **Prepare this Android phone**, and continue with the next
   permission. The status screen always reflects current Android grants.
5. Phase 1 permits continuing with missing grants so you can inspect/test the
   foundation. It displays a warning. No combination of grants makes this phase
   safe for unsupervised use. Accessibility is optional until enforcement exists.
6. In parent space, open installed launchable apps, inspect permissions, change
   PINs (requires the current parent PIN again), or lock the launcher.
7. On the launcher lock screen, the new child PIN opens Kids Mode. **Parent
   access** requires the parent PIN; the child PIN counts as a wrong attempt.

Revocations are checked while foregrounded every ten seconds and immediately on
resume. Notifications while this app is not running are outside Phase 1.

## Limits and recovery

This is a launcher, **not Android's system keyguard**. Configure the system screen
lock too. Neither Device Admin nor Accessibility provides an uninstall-proof or
inescapable kiosk. See [security boundaries](SECURITY.md).

There is no secret recovery PIN. If credentials are forgotten, Android-level
deactivation/uninstall/data clearing can reset local setup; those mechanisms
also show why this architecture cannot promise child-proof containment. Device
clock changes can affect wall-clock lockout. Hardware-level credential extraction
and compromised/rooted devices are outside its protection.

## Remaining phases

1. **Current:** project, PIN security, launcher shell and permission wizard.
2. Proposed after your `next`: agree the next slice, then implement parent/child
   profiles, authenticated Firebase family pairing and offline task persistence,
   with Firestore rules/emulator tests before enabling remote reads or writes.
3. Task engine, original age-based content, rewards and their unit tests.
4. Parent-approved learning media, content gating and enforceable timer scope.
5. Remote schedules, time requests, push delivery and conflict handling.
6. Best-effort Android restrictions, real-device adversarial testing, accessibility
   policy review, privacy review and signed release hardening.

Firebase Auth/Firestore/FCM are intentionally **not initialized in Phase 1**.
No credentials are needed for local PIN setup. The checked-in Firebase rules deny
all access until authenticated ownership rules and tests are built. See
[Firebase preparation](FIREBASE_SETUP.md), [device validation](DEVICE_TESTS.md)
and [Play release checklist](PLAY_RELEASE_CHECKLIST.md).

To read every file in one document, run `python3 tool/export_source.py` and open
`docs/FULL_SOURCE.md` in the repository root. It contains full file contents, without code excerpts.
