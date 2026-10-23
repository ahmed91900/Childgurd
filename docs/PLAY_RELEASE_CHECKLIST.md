# Play Store release gate — not complete in v0.2 beta

- [ ] Finish the requested core features and remove any claims for unsupported
  capabilities. Do not distribute this beta as child-proof protection.
- [ ] Complete the physical-device matrix in `DEVICE_TESTS.md`; record devices,
  versions, results, known escape paths and minimum supported hardware.
- [ ] Review the latest Google Play AccessibilityService policy, submit the
  required permission declaration and accurate demonstration video, and obtain
  approval where required. `isAccessibilityTool` must remain false for this
  parental-control use. Prominent in-app disclosure and affirmative consent
  must precede activation. Do not coerce or silently enable the service.
- [ ] Assess whether the final Accessibility use is permitted. If it is not,
  redesign the feature or choose a lawful distribution approach; never mislabel
  it as a disability-support service or claim guaranteed Play acceptance.
- [ ] Review Device Admin, overlay, Usage Access, installed-app visibility,
  background activity launches and target-API restrictions. Request only
  permissions justified by implemented functionality. Consider omitting inert
  permissions entirely from an early public build.
- [ ] Review Families/target-audience policy and restrictions on child-directed
  apps, SDKs, external links, videos, advertising and monetization.
- [ ] Publish an accurate hosted privacy policy; complete Data Safety using the
  actual final SDK behavior. Obtain legal review for COPPA/GDPR-K and applicable
  regional child-consent requirements. Add verified guardian consent where needed.
- [ ] Implement account deletion, family/device unpairing, retention, export and
  consent withdrawal before adding child cloud records. Avoid child identifiers
  in FCM payloads and logs. No plaintext or hashed device PINs in Firebase.
- [ ] Test Firebase rules with hostile clients, cross-family access, offline
  replay and device-revocation cases. Require trusted backend authorization for
  pushes and privileged mutations. Remove any development endpoints.
- [ ] Validate original content and asset/SDK licenses. Material icons come
  from Flutter; launcher artwork is original vector code. Add attribution and
  accessible open-source notices for the complete final dependency set.
- [ ] Audit dependencies and pinned toolchains for supported versions and known
  vulnerabilities. Pin CI actions to reviewed commit SHAs and protect release jobs.
- [ ] Benchmark PIN hashing on low-end hardware; revisit work factor and hash
  migration. Test tamper/storage failures and document recovery tradeoffs.
- [ ] Use your own unique application ID if `com.kidsafe.launcher` is unavailable.
  Configure production Firebase for that ID only when implemented.
- [ ] Create a private upload key, enable Play App Signing, configure release
  signing using CI/environment secrets, and store backups securely. Never commit
  keystores or use debug signing for release.
- [ ] Build a signed `flutter build appbundle --release`, inspect its merged
  manifest and permissions, run Android lint, prelaunch/accessibility reports and
  internal/closed testing. Verify current target API and 16 KB page requirements.
- [ ] Verify RTL, TalkBack, text scaling, child-safe labels, low-bandwidth/offline
  flows, battery behavior and OEM restrictions on the final release artifact.
- [ ] Prepare honest listing text, screenshots, support contact, parental setup
  guide and limitations. No absolute blocking, uninstall-proof or compliance claims.

No release key, production Firebase deployment, Store submission or policy approval is included in this beta. Rules, callable functions, account deletion and owner media controls are emulator-tested; production operation remains a separate release gate.
