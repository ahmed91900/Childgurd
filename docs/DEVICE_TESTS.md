# Real-device validation gate

Unit/widget tests do not replace the following Android checks. None of these
checks is claimed as passed merely because an APK builds. Use test data only.

| Area | Required manual checks |
| --- | --- |
| OS/OEM matrix | API 26, 29, 31, 33, 35, 36; Pixel plus Samsung and at least one restrictive OEM; low-memory/low-end device |
| Initial setup | Consent required; `1020` challenge; both defaults rejected as replacements; mismatched confirmations; Bangla/Arabic/Persian numerals; keyboard does not obscure buttons |
| Mode routing | Correct parent/child routes; wrong PIN; child PIN rejected for exit and change; installed apps launch in parent mode only |
| Lockout | Five failures, correct PIN denied during lockout, kill/relaunch, reboot, countdown expiry, background/foreground, clock changes and timezone changes |
| Storage | Keystore key creation, AES-GCM encrypted vault, no plaintext PIN in app files/logcat; native storage failures fail closed; backup/device-transfer exclusions |
| Lifecycle | Home/back/recents, screen off/on, incoming calls, rotation, multiwindow, process death during hashing or permission prompt; pending work must not restore parent access |
| Home | Select/revoke default launcher; chooser cancel; other launcher installed; Home works after reboot/process death |
| Device Admin | Grant/deny/cancel/revoke, deactivation then uninstall, no wipe/lock policies, no false uninstall-proof claim |
| Accessibility | Explicit OS consent, sideload restricted settings, revoke, service restart/crash; confirm package-only best-effort redirection and no screen-content collection |
| Overlay/usage | Grant/deny/revoke; OEM settings fallbacks; truthful status on return; no blank or falsely granted status |
| Revocation | Revoke each grant; warning on resume and within ten seconds while foregrounded; errors never appear as granted |
| Privacy | Airplane-mode setup and PIN flow; offline learning without an account; configured SDK/network behavior; privacy screen in all three languages; Android backups disabled |
| Accessibility/UI | TalkBack semantics, 200% text size, high contrast, 320dp width, RTL reading order, large targets, no clipped PIN fields, screenshot/recents protection |
| Escape behavior | Settings, quick settings, recents, safe mode, emergency UI, uninstall/data clearing; document remaining escape paths honestly |

There is no emulator/phone validation of Kotlin runtime or OEM behavior unless
recorded separately with device/OS and observed results. Cloud widget tests mock
the Android method channel; they validate UI and routing, not permission grants.

Connected-build and media gates: actual offline progress/sync conflicts; reward replay/idempotency;
parent/child Firestore isolation; remote pairing revocation; FCM delayed delivery;
video allowlisting, Shorts rejection and no-autoplay behavior; app-blocking races;
clock/reboot-safe daily limits; battery restrictions; permission-abuse resistance.

Also test installed/missing English and Bangla offline TTS voices, picker return requiring parent PIN, manual ad upload MIME/size restrictions, owner/guardian ad toggles, no autoplay, account deletion on a live development project, local data reset, native storage near capacity, drawings and 30-day retention. No real-device, audio-quality, push-delivery, battery, Android permission, or OEM restriction result is currently recorded as passed.
