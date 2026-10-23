# KidSafe Launcher roadmap

The project progresses through reviewed phases. Planned items are not features
of the current build. App implementation waits for the owner's next instruction.

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Project architecture, PINs, launcher shell, permission wizard, English/Arabic | Implemented; automated validation recorded; device checks pending |
| 2 | Parent accounts, profiles, authenticated family/device pairing, local-first tasks | Planned; exact slice to be agreed |
| 3 | Original learning tasks, difficulty, completion logic and rewards | Planned |
| 4 | Parent-approved learning media, task gates and daily limits | Planned |
| 5 | Remote assignments, schedules, time requests, Firestore sync and FCM | Planned |
| 6 | Best-effort Android restrictions, device validation and release hardening | Planned |

## Gates for future work

- Cloud access needs authenticated family ownership, paired-device privileges
  and emulator-tested rules. The current Firebase baseline denies all clients.
- Task completion and rewards need offline behavior, idempotency and meaningful
  unit tests before remote synchronization.
- Learning media needs content-source, allowlisting, privacy and playback-policy
  decisions before a provider is integrated.
- Android restrictions need prominent consent, policy review, physical-device
  tests and visible limitations. User-granted permissions cannot promise kiosk
  containment or uninstall-proof protection.
- Production distribution needs guardian/privacy review, signed release builds,
  a support process and the [release checklist](PLAY_RELEASE_CHECKLIST.md).

See [Phase 1 evidence](PHASE1_VALIDATION.md) for what has actually been verified.
