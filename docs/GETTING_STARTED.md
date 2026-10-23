# KidSafe Launcher v0.2 beta setup

## Download and installation

Download `KidSafe-Launcher-arm64-beta.apk` from [GitHub Releases](https://github.com/extramail9922-alt/Childgurd/releases/tag/v0.2.0-beta.1). Android 8.0+ and ARM64 are required. Compare the APK SHA-256 with the release's `SHA256SUMS` if desired. This is a debug-signed beta; it will not upgrade a differently signed installation. Back up any data you need before uninstalling another build. Local encrypted data cannot be recovered after uninstall/data clearing.

Open the APK from Downloads. Android may ask you to allow installation from the browser/file manager. That grant only allows installation; it is separate from KidSafe's permissions. Do not disable Play Protect. Keep an alternative launcher available during testing.

## First run

1. Choose English, বাংলা or العربية from the language menu. Arabic uses RTL.
2. Read the privacy policy and parental consent. These disclosures do not independently verify legal guardianship.
3. Enter initial parent PIN `1020`. Choose two different PINs of 4–12 digits and confirm each. Neither `1020` nor `0000` may be retained. Longer private PINs are better.
4. Work through Android settings below. Returning from an external screen locks the parent space; enter the new parent PIN again. A child PIN never authorizes the parent dashboard.
5. Complete setup even if an optional permission is unavailable. Missing/revoked permissions are visible; do not rely on restrictions when required grants are absent.

| Setting | Purpose and limit |
| --- | --- |
| Default Home | Choose KidSafe as Home. Android's system screen lock stays independent. |
| Device Admin | Android commonly requires deactivation before uninstall; the user can deactivate it. No wipe policy is requested. |
| Accessibility | Read the prominent disclosure and explicitly consent before opening Android's enable screen. Package changes trigger best-effort return Home in child mode. No screen text is read. Sideloaded apps may need Android's “Allow restricted settings” option in App info before this can be enabled. Follow the OS instructions. |
| Display over apps | Optional status/guidance; this build does not use overlays for blocking. |
| Usage Access | Optional status/guidance; this build measures its own play/media time and does not inspect other apps' usage history. |
| Notifications | Requested only when setting up cloud pairing/account sync; declining does not prevent offline lessons. |

## Parent dashboard

Set the child's nickname, age, difficulty, daily play/video/story minutes, required tasks and enabled activity types, then save. Create scheduled custom questions with an answer, start date and deadline. Task library items can be toggled individually. Additional child profiles require a unique child PIN and the current parent PIN. The default child uses the child PIN set at first run.

The dashboard shows today's completed tasks, points and foreground media time, plus weekly totals. Stars represent virtual points; there are no purchases. A more-time request grants ten minutes only after a parent approves it, once for that request/date. The daily allowance is shared between games, stories and videos; open learning tasks and alphabet exercises remain available.

Approve direct HTTPS MP4 files you have reviewed and have permission to use. YouTube/channel URLs, Shorts feeds and browsers are not embedded. Video is online-only in this version. Remote sources can change content: periodically review them.

For narration install English/Bangla offline voice data in Android's text-to-speech settings, then use Listen. Voice availability varies by device; no voice pack is bundled. The parent dashboard links to the system voice settings.

## Same phone and separate phones

Same-phone profiles, tasks, rewards, requests and time settings work offline. No account is required.

Separate-phone assignment/progress and global advertising need a Firebase-configured APK and deployed backend. The public beta intentionally has no production project configured. Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) to build that edition. Pairing uses a short-lived private code, not the parent PIN. Don't share pairing codes publicly. One child profile has one active paired phone; pairing a replacement revokes the earlier phone's online access. Revocation does not erase its previously downloaded offline data or turn the phone into a managed kiosk.

## Ads

Ads are off by default. After Firebase activation, the app owner can turn them on/off and select AdMob, an original image, or an MP4. A guardian must also opt in for each child. Manual ads have no external click link; video requires play and shares the child's play allowance. Changing global settings requires an authenticated `owner` claim, never a client-editable role. Image/video uploads accept at most 20 MB. Upload only public advertising material: download URLs can be shared. After the picker, unlock with the parent PIN again, upload the chosen file, then save the ad settings.

## Recovery and uninstall

Five incorrect attempts lock all PIN routes for five minutes, including after restarting the app. Keep the parent PIN private; there is no hidden master PIN or remote PIN upload. Android wall-clock manipulation can affect lockout/daily limits, so protect device settings separately.

To stop testing, enter parent mode, choose another Home launcher in Android settings, deactivate KidSafe Device Admin, revoke Accessibility, and uninstall normally. If the parent PIN is lost, Android settings/data clearing may be necessary and will erase local data. This app is not uninstall-proof. Never rely on it as the only way to access emergency functions.

## Local development

Install Flutter 3.35.7, JDK 21 and Android SDK platform 36, build-tools 35.0.0, platform-tools, NDK 27.0.12077973 and CMake 3.22.1. Accept Android SDK licenses through the official SDK tools. Run the build/check commands in the repository README. `tool/cloud-env.sh` contains paths for this workspace only; use your own SDK/JDK locations elsewhere. Release signing must be configured privately before Store distribution.
