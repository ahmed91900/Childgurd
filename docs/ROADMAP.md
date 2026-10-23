# Current scope and remaining release work

v0.2 beta includes offline family learning, nine activity types, English/Bangla alphabet lessons and original stories, local parental tasks/rewards/time controls, secure profile PINs, Android setup and best-effort app redirection. Firebase parent/child pairing, progress/assignment sync, trusted push functions and owner-controlled ads are implemented and emulator-tested.

Before a production release:

- Supply and deploy the owner's Firebase project; build the configured connected APK and validate two actual phones, push delivery, reconnect and revocation.
- Complete the physical-device/OEM escape, battery, accessibility, offline TTS and low-end performance matrix.
- Configure durable private release signing and validate a signed AAB, target API and native 16 KB compatibility.
- Complete Accessibility declaration, Families/advertising SDK review, hosted privacy policy, guardian/retention/export/support processes and the Play checklist.
- Review cloud retention and abuse controls, add App Check/operational limits, benchmark per-second persistence and content-review workflows.

Not currently implemented: device-wide adult-content/network filtering, guaranteed kiosk containment, YouTube/channel embeds, offline video downloading, a general allowed-external-app editor for child mode, downloadable/bundled narration, arbitrary multi-device collaborative configuration, remote erasure of offline copies, or monetization activated without owner configuration. Parent mode can launch normal phone apps; child mode exposes only KidSafe and necessary trusted system/keyboard surfaces.

The [Phase 1 report](PHASE1_VALIDATION.md) is historical. See [current validation](VALIDATION.md) for v0.2 evidence.
