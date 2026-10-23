# Security boundaries — Phase 1

## Credential handling

Production uses PBKDF2-HMAC-SHA256 with 210,000 iterations and a fresh 16-byte salt
per credential change. Store only algorithm/version, salt and 32-byte derived
key. Compare all digest bytes without an early exit. Real hashing tests exercise
correct and incorrect inputs and random salt independence. Fast fake hashers
are confined to service/widget tests.

The iteration count is an initial performance/security choice, not a claim of
meeting every current password-hashing guideline. Before release, benchmark
supported low-end phones, increase work factor where practical, and implement
explicit hash migration when parameters change. A four-digit PIN has only
10,000 possibilities; encourage longer PINs. Keystore-backed encryption and app
lockout do not turn short PINs into high-entropy passwords.

The small Kotlin vault encrypts one JSON record with AES-256-GCM and a
non-exportable Android Keystore key, bound to the package/schema with additional
authenticated data. Each write uses a fresh provider-generated 96-bit nonce.
The record contains both hashes, schema version, retry count, lockout deadline
and last observed wall time. Native AtomicFile plus explicit file-descriptor
sync and readback ensure a write is acknowledged only after durable persistence.
Crypto and disk IO run on a serial native executor. Missing keys, missing data
with a surviving key, authentication-tag failure and corrupt envelopes fail
closed. Hardware backing is used when supplied by Android, not guaranteed. Failed storage reads/writes do
not authorize a session. Malformed records are never silently reset. Backups
and device transfers are disabled to avoid moving encrypted data without keys.
Verify those guarantees on target OEMs; rooted/compromised OSes are unsupported.

Five wrong attempts set a persisted five-minute deadline and reset the attempt
counter for the next window. Valid PINs do not bypass an active deadline. Both
roles share the counter so switching roles cannot bypass it. Attempt processing
is serialized. Failed parent-only challenges count even when a valid child PIN
is supplied. The clock floor prevents simple backward clock movement from
shortening a deadline. Moving the wall clock forward can expire a lockout;
secure time across reboot is not provided by ordinary Android app privileges.

Credential replacement reauthenticates the parent and atomically writes both
replacement hashes at the encrypted-record boundary. Abrupt hardware power loss
is still subject to the device filesystem guarantees. Flutter and native parent
sessions are memory-only. Focus loss, backgrounding, process death or screen-off lifecycle
transitions remove authorization. Pending async work cannot reopen a parent
screen after a background transition. `FLAG_SECURE` suppresses normal screenshots
and recents previews; it does not defeat cameras or a compromised OS.

## Android constraints

- Home selection changes where the Home gesture/button leads. It does not
  replace Android keyguard, block recents or prevent notification interactions.
- Device Admin is a legacy user-granted API. Android may require deactivation
  before uninstalling, but a user can deactivate it. No wipe, password or remote
  lock policies are requested. No Device Owner or ADB workflow is used.
- Accessibility in Phase 1 is deliberately inert. It has no window-content
  access, gesture injection, logging or networking. It must not be advertised as
  an accessibility tool for disabled users. Future enforcement needs a separate
  prominent disclosure, policy review and real-device tests.
- Even a later Accessibility blocker is best effort: race conditions, crashes,
  OEM behavior, system dialogs, restricted settings and revocations remain.
- Overlays can be suppressed on sensitive system surfaces. They cannot secure
  Android Settings or system dialogs, and can conflict with permission prompts.
- Usage Access does not automatically enforce time limits or guarantee accurate
  foreground accounting. Phase 1 does not query usage events.
- Safe mode, clearing storage, uninstalling, factory reset, rooted devices,
  alternative boot environments, emergency UI and system settings cannot be
  reliably contained with these user-granted permissions.
- Sideloaded apps on newer Android versions may require the parent to explicitly
  allow restricted settings before enabling Accessibility. Explain OS prompts;
  never attempt to bypass them.

There is no promise that granting all permissions makes every requested feature
work. Unsurmountable platform limits must remain visible in onboarding and store
copy. True managed kiosk guarantees require a different enrollment model, which
the requested no-Device-Owner design excludes.

## Privacy and future cloud work

Phase 1 sends no application data to Firebase and has no analytics or advertising
SDK. The package visibility query lists launchable apps only; it does not request
`QUERY_ALL_PACKAGES`. No child profile data, content, location, contacts, camera
or microphone is collected. Native services do not transmit data.

Parental consent is local and informational, not verified legal identity.
Before child cloud data is added, define legal basis/guardian verification by
region and age, family pairing, least privilege, account/data deletion, retention,
processor agreements, encryption, breach procedures and parental export rights.
Do not claim COPPA/GDPR-K compliance from a checkbox or Firebase security rules.

Future cloud code must never store plaintext PINs or their hashes in Firestore.
Device PIN authorization is distinct from Firebase parent identity. A child's
paired device must not possess unrestricted parental credentials. Family IDs,
notification payloads, server timestamps and replay/abuse controls need tested
authorization semantics. No permissive development rules may reach production.
