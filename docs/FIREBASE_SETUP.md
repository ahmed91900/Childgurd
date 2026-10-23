# Firebase setup — offline beta to connected build

The public APK works offline and does not contain a production Firebase project. Cloud source and emulator tests are included; nothing has been deployed to your account. Use a project you own. Never send service-account keys, passwords or upload keystores in chat.

## 1. Create a development project

1. In Firebase Console create separate development/production projects. Choose Firestore's region deliberately; backend functions currently use `us-central1`.
2. Register Android package `com.kidsafe.launcher` (change it consistently if you need another ID). Obtain the Android public config: apiKey, appId, messagingSenderId, projectId and storageBucket. These client identifiers are not Admin credentials; restrict their API/application use appropriately.
3. Enable Auth **Email/Password** for parents and **Anonymous** for scoped child devices. Configure authorized domains and email-verification templates. Verification proves email control, not guardianship.
4. Create Firestore in production/locked mode and enable Cloud Storage. Trusted functions/Storage may require a billing plan. Set budget alerts and review current Firebase pricing before enabling billable services.
5. Enable the FCM HTTP v1 API for backend delivery. No server key goes into the app.

## 2. Test locally first

Install Node 22, Java 21 and the pinned npm lockfiles:

```sh
npm ci --prefix firebase/functions
npm ci --prefix firebase/rules-tests
firebase/rules-tests/node_modules/.bin/firebase emulators:exec \
  --only auth,firestore,functions,storage --project demo-kidsafe \
  --config firebase/firebase.json 'npm --prefix firebase/rules-tests test'
```

These tests exercise 14 Firestore rule cases, 8 actual callable-function integrations and 4 Storage rule cases, including denial paths. They use only `demo-kidsafe`, not your live project. Emulator notifications are intentionally suppressed. The APK is not automatically routed to localhost emulators; these are server tests, not end-to-end Android networking tests. On a proxy-controlled machine the emulator processes/local calls need direct loopback networking; predownload emulator binaries with the approved network path first.

## 3. Deploy to your chosen project

Authenticate the Firebase CLI locally using your own authorized operator account. From the repository root:

```sh
firebase/rules-tests/node_modules/.bin/firebase login
firebase/rules-tests/node_modules/.bin/firebase deploy \
  --project YOUR_PROJECT_ID --config firebase/firebase.json \
  --only firestore:rules,firestore:indexes,storage,functions
```

Inspect the exact project before confirming deployment. Never use public test rules. Protect Admin credentials outside Git. Review function IAM, limits, service accounts, logs and billing. The functions run on Node 22; public callable endpoints enforce Auth and role checks in their handlers. Evaluate App Check and additional per-IP/account abuse protection before production.

## 4. Build the connected app

Copy `firebase-config.example.json` to ignored `firebase-config.json`. Set `FIREBASE_CONFIG` to a JSON **string** containing the Android public values, including storageBucket for owner uploads. Leave `ADMOB_APP_ID` empty unless deliberately configuring AdMob. Example (replace every placeholder):

```json
{
  "FIREBASE_CONFIG": "{\"apiKey\":\"YOUR_PUBLIC_API_KEY\",\"appId\":\"YOUR_ANDROID_APP_ID\",\"messagingSenderId\":\"YOUR_SENDER_ID\",\"projectId\":\"YOUR_PROJECT_ID\",\"storageBucket\":\"YOUR_BUCKET\"}",
  "ADMOB_APP_ID": ""
}
```

```sh
flutter pub get --enforce-lockfile
flutter build apk --debug --target-platform android-arm64 \
  --dart-define-from-file=firebase-config.json
```

Gradle reads these same defines and creates the native Firebase resources needed for FCM. You do not need to commit `google-services.json`, and no Google Services Gradle plugin is required for this explicit configuration. Check identifiers match one Android Firebase app. Never use service-account JSON as `FIREBASE_CONFIG`.

For Store builds, configure private release signing first, then build an AAB with the same defines. Debug signing is only for this beta, not Play distribution.

## 5. Pair parent and child phones

1. Install the configured build on both phones and complete local consent/PIN setup on each.
2. On the parent's phone, enter the parent dashboard, create an email/password account, verify the email, then sign in again. Create/configure a child and tap Sync before generating a pairing code.
3. On the child's phone, an authenticated local parent enters that code in the cloud panel. The child phone signs in anonymously; it never receives the parent's password or PIN hash. Codes are private, one-use and valid for ten minutes.
4. Use the default child PIN on the paired phone. Its default local profile maps to the remotely selected child. Other local child profiles are not mapped to the same remote identity. Keep additional children on separate paired devices or use local same-phone mode.
5. Assign a scheduled task on the parent phone, wait for sync, complete it on the child phone, and confirm progress on the parent phone. Test airplane mode, restart, reconnect, delayed pushes and revoked pairing. Use one parent phone as configuration authority; simultaneous parent edits are last-write-wins.

One active paired device per remote child is supported. Pairing a replacement revokes the previous online identity but does not erase its offline copy. Same-phone offline mode does not require an account. Entering child mode signs out unrestricted parent Auth so the child does not retain those online privileges; use a paired child identity for online child reporting.

## 6. Owner-controlled ads

Only the operator can grant the `owner` Auth custom claim, using Admin credentials through Application Default Credentials outside this repository:

```sh
node firebase/functions/owner-admin.cjs grant-owner YOUR_PROJECT_ID OWNER_AUTH_UID
```

Sign out/back in to refresh the token. The owner section appears in the parent cloud panel. Global ads start off; choose AdMob, image or video and save the on/off setting. Guardians must independently enable ads for each child. Normal parents/children cannot write owner flags or upload ads.

- **AdMob**, not website AdSense, is the Google mobile-app product. Configure a legitimate AdMob Android application ID at build time and banner unit in the owner panel. Use Google's test IDs during development; never test by clicking live ads. The app uses child-directed/under-consent tags, G rating and nonpersonalized requests. Confirm Families eligibility, consent/region requirements and current SDK policy before live use.
- **Manual ads:** choose original/authorized PNG/JPEG/WebP or MP4, maximum 20 MB. Returning from Android's picker requires the parent PIN again; then upload and save. Hosted HTTPS media URLs can also be entered manually. Firebase download URLs can be shared by anyone holding them. Upload only public advertising content; no child photos or confidential data. Images have no click-through link; video plays deliberately within the time gate. Offline cached media campaigns are not implemented.
- **Emergency off:** `node firebase/functions/owner-admin.cjs ads-off YOUR_PROJECT_ID`. Offline clients cannot receive a new global flag until connected. To remove ownership use `revoke-owner PROJECT_ID UID`.

## 7. Production operations still required

Configure and disclose retention for cloud progress/requests, expired pairing codes and pairing-rate records; the beta does not automatically delete old cloud history. Local details are bounded to 30 days. Implement an operator-reviewed export/guardian-request process. Account deletion is implemented and emulator-tested; local copies on other phones require local deletion. A minimal inactive server tombstone blocks late writes after deletion.

Complete real-device FCM/background/reconnect tests, adversarial client testing, signing, hosted privacy/account-deletion support, verified guardian requirements, consent withdrawal and Store policy review. Emulator success is not proof of production delivery, legal compliance or child-proof Android containment.
