KidSafe Launcher v0.2.3 beta brings offline English/Bangla learning and same-phone family controls to Android 7.0+ phones with 32-bit ARM, 64-bit ARM or x86-64 CPUs.

### Download
Choose **KidSafe-Launcher-universal-beta.apk** below. Open it on your Android phone; Android may ask permission to install from your browser/file manager. First setup has two fields: **Parent PIN** and **Kids PIN**. Choose your own different 4–12 digit PINs and use the eye icons to check them. Existing PIN changes verify the current parent in a separate step. This is a **debug-signed development beta for supervised testing**, not a Play Store release.

### Included
- Nine learning activity types: math, reading, memory, number patterns, drawing, vocabulary, spelling, counting and shapes.
- 26 English letters, 50 Bangla letters/signs, matching quizzes and optional offline Android TTS. Install offline language voices on the phone for sound.
- Four original animated stories in English/Bangla; no copied repository assets or public social-media feed.
- Local child profiles/PINs, scheduled custom tasks, points/stars, progress reports, task gates, foreground play/media limits and parent decisions on more-time requests.
- English/Bangla/Arabic UI, guided Android permissions, encrypted local data and persistent PIN lockout.
- Firebase pairing/sync/push and owner-controlled AdMob/manual image/video ads implemented in source, with 30 passing backend tests.

### Important limits
**This public APK has no production Firebase project configured.** Offline learning and same-phone controls work without an account. Separate-phone sync and owner ad settings require your Firebase project, backend deployment and a configured rebuild; see the Firebase setup guide. Ads are off by default. Enabling ads requires an owner claim and per-child guardian consent; live AdMob IDs/policy approval are not included.

Accessibility redirection is best effort. Android system settings, recents, notifications, safe mode, permission revocation, uninstall and factory reset cannot be guaranteed blocked. This is not device-wide adult-content filtering. Only parent-reviewed direct HTTPS MP4 media is supported, online; no YouTube/channel embeds or video downloads. Device-clock changes affect limits. Real-device/OEM, voice, battery and production sync tests remain required.

### Verification and source
59 Flutter tests and 30 Firebase emulator tests passed; Flutter analysis, APK build, Android lint and APK signature verification passed in the cloud workspace. See `docs/VALIDATION.md` in the source/repository for exact scope and untested device behavior.

**FULL_SOURCE.md** contains every project file's full contents (binary files base64 encoded). **KidSafe-Launcher-source.zip** is the complete clean source tree. **SHA256SUMS** contains artifact checksums. No private signing/Firebase credentials are included.

### v0.2.1 fix
Guardian-authored numeric answers and child input now use the same Bangla/Arabic/Persian digit normalization. Three regression tests cover cross-script custom answers. This beta is signed with the CI build's debug key; a differently signed previous build must be uninstalled before installing. Uninstalling erases its local data.

### Broader Android compatibility
One universal APK now includes armeabi-v7a, arm64-v8a and x86_64. The minimum Android version is lowered from 8.0 to 7.0 (API 24, required by the video-player plugin). Packaging verification checks each Flutter engine's ELF architecture, the actual minimum SDK, ZIP integrity and APK signature.

This does not support iPhones/iPads, Android 6 or earlier, 32-bit x86, or operating systems that cannot install Android APKs. Phone-brand permissions, offline voices, video decoders and background behavior still need real-device testing. The APK is larger because it includes three architectures. On devices without Google Play services, cloud push and Google ads may be unavailable.

### Simpler setup and Google-linked backup
The five-field PIN form is replaced with two choices and a Save PINs button. Google sign-in, private learning backup and fresh-phone restore are included in source; the public APK keeps these disabled until the operator supplies Firebase options, a Google Web OAuth client ID and signing-certificate registration, enables Google Auth, and deploys the rules/backend. Offline learning and the simple PIN setup are available now. PINs/hashes never enter backups; each receiving phone chooses its own PINs. Backups save only while a parent Google session is connected and online; data since the last successful backup needs reconnecting before it is recoverable. Actual Google chooser and production recovery tests are pending.
