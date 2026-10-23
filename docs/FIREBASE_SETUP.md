# Firebase preparation — activation deferred

Phase 1 is intentionally local. There is no Firebase SDK initialization and no
parent account or remote pairing screen. Do not treat this document as proof of
a working backend. The included rules fail closed for every client.

For the later Firebase phase:

1. Create separate development and production projects in Firebase Console.
   Select the Firestore region with data residency, latency and family location
   in mind before creating the database. Use minimal child data.
2. Register Android application ID `com.kidsafe.launcher`. Add SHA fingerprints
   from your own signing keys only for chosen Auth providers. Keep private
   signing keys and service accounts out of this repository and chat.
3. Enable the selected parent-only Auth provider, configure account deletion
   and recovery, and choose an appropriate guardian verification process.
   Email verification alone does not prove legal guardianship.
4. Create Firestore in locked/production mode. Never use time-limited public
   test rules. This repository's deny-all baseline can be deployed from the
   `firebase/` directory with `firebase deploy --only firestore:rules
   --project YOUR_DEVELOPMENT_PROJECT` after local Firebase CLI authentication.
5. In the Firebase implementation phase, add pinned FlutterFire dependencies,
   run `flutterfire configure --platforms=android` for the development project,
   and keep generated local project configuration out of Git. Add the Google
   Services Gradle plugin only when the actual Firebase integration is built.
6. Design authenticated parent-owned family paths and device pairing before
   opening rules. Parent ownership must come from Firebase Auth, never a
   client-supplied PIN or writable role field. Pair child devices with scoped
   identities/claims, not shared unrestricted parent credentials. Add rule tests
   for cross-family denial, unauthenticated denial, forged ownership, immutable
   family/device identities, child privilege limits and deletion.
7. Use the Firebase Emulator Suite for Auth, Firestore, rules and backend tests.
   Explicitly connect debug builds to emulators; release builds must never use
   emulator hosts. No emulator connectivity code is implemented yet.
8. Enable FCM and request notification permission on API 33+ when its purpose is
   explained. Send push messages only from a trusted backend with authorization
   checks. FCM is an unreliable wake-up hint; Firestore is the source of truth.
   Never embed admin credentials or push-server secrets in the APK.
9. Implement Firestore disk persistence and a tested local-first task/reward
   model with idempotent completion events and conflict handling. Offline
   authorization revocation and delayed writes require explicit policy.
10. Before production, complete retention/deletion/export flows, App Check
    evaluation, abuse controls, privacy/guardian-consent review, budget alerts,
    crash-report redaction and signed-release verification.

The next phase must include actual SDK integration, ownership rules and emulator
tests; writing this checklist does not complete that work. No secret values or
Firebase account access are required to test Phase 1.
