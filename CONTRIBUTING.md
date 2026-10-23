# Contributing to KidSafe Launcher

Start with the [setup guide](docs/GETTING_STARTED.md),
[roadmap](docs/ROADMAP.md) and [security boundaries](docs/SECURITY.md).
Discuss feature scope before implementing another phase.

## Make a focused change

1. Describe the user problem and the expected behavior.
2. Keep domain policy separate from storage, Android APIs and UI code.
3. Add English, Bangla and Arabic strings together. Check RTL and text scaling.
4. Use original or appropriately licensed content and record attribution.
5. Add tests for changed security or task behavior; state what still requires a
   physical device. Do not describe mocked Android calls as device validation.
6. Keep PINs, signing keys, service accounts, local SDK paths and family data out
   of commits, screenshots and logs.

## Validate

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
flutter build apk --debug --target-platform android-arm64
```

For native Android changes, also run:

```sh
./android/gradlew -p android :app:lintDebug -Ptarget-platform=android-arm64
```

Describe the problem, final behavior, validation and remaining limitations in
your pull request. Use the PR template as a guide. Documentation-only edits
need a review of relative links, commands and claims rather than a fresh APK.

For a suspected security issue, do not post private data or an exploit publicly.
Use GitHub's private vulnerability reporting if the repository owner enables it.
If it is unavailable, obtain a private channel before sharing sensitive details.
