KidSafe Launcher v0.2 beta brings offline English/Bangla learning and same-phone family controls to Android 8.0+ ARM64 phones.

### Download
Choose **KidSafe-Launcher-arm64-beta.apk** below. Open it on your Android phone; Android may ask permission to install from your browser/file manager. Initial parent PIN: **1020**. Both default PINs must be changed during setup. This is a **debug-signed development beta for supervised testing**, not a Play Store release.

### Included
- Nine learning activity types: math, reading, memory, number patterns, drawing, vocabulary, spelling, counting and shapes.
- 26 English letters, 50 Bangla letters/signs, matching quizzes and optional offline Android TTS. Install offline language voices on the phone for sound.
- Four original animated stories in English/Bangla; no copied repository assets or public social-media feed.
- Local child profiles/PINs, scheduled custom tasks, points/stars, progress reports, task gates, foreground play/media limits and parent decisions on more-time requests.
- English/Bangla/Arabic UI, guided Android permissions, encrypted local data and persistent PIN lockout.
- Firebase pairing/sync/push and owner-controlled AdMob/manual image/video ads implemented in source, with 26 passing backend tests.

### Important limits
**This public APK has no production Firebase project configured.** Offline learning and same-phone controls work without an account. Separate-phone sync and owner ad settings require your Firebase project, backend deployment and a configured rebuild; see the Firebase setup guide. Ads are off by default. Enabling ads requires an owner claim and per-child guardian consent; live AdMob IDs/policy approval are not included.

Accessibility redirection is best effort. Android system settings, recents, notifications, safe mode, permission revocation, uninstall and factory reset cannot be guaranteed blocked. This is not device-wide adult-content filtering. Only parent-reviewed direct HTTPS MP4 media is supported, online; no YouTube/channel embeds or video downloads. Device-clock changes affect limits. Real-device/OEM, voice, battery and production sync tests remain required.

### Verification and source
48 Flutter tests and 26 Firebase emulator tests passed; Flutter analysis, APK build, Android lint and APK signature verification passed in the cloud workspace. See `docs/VALIDATION.md` in the source/repository for exact scope and untested device behavior.

**FULL_SOURCE.md** contains every project file's full contents (binary files base64 encoded). **KidSafe-Launcher-source.zip** is the complete clean source tree. **SHA256SUMS** contains artifact checksums. No private signing/Firebase credentials are included.
