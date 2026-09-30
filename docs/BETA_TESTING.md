# FarmersHub GH Android beta 0.3.0 (build 3)

## Release gate
**Current blocker:** deployed Firestore allowed cross-account farm reads. Deploy the owner-only rules and rerun `scripts/firebase_acceptance.py` before widening the beta.

Distribute only after the signed release APK has passed the Android launcher smoke test and the connected Firebase acceptance checks below. A successful compile alone does not satisfy this gate.

## Installation
Use Android 7.0 or later. Download the signed APK from the agreed beta release channel, allow installation from that source, and install. Existing testers can update only if the previous APK used the same signing certificate; otherwise back up/confirm synced records, then reinstall. Record the APK SHA-256, certificate SHA-256, app version and source commit with every distributed build.

## First use
Connect to the internet to create an account using an email and password (at least six characters). The phone field is optional and is a contact detail, not a phone sign-in option. Register a farm, add a crop, and enter income and expenses. Use GH₵ amounts and the same yield unit when comparing yield and selling price.

## Acceptance checklist
- Clean install opens the FarmersHub login screen without a blank screen or crash.
- Empty/incorrect credentials show readable errors; password reset works.
- Register a fresh account; sign out and sign back in.
- Register a farm, add a crop, and create an expense and an income linked to that crop.
- Example: expense GH₵100, income GH₵160, 2 acres, expected yield 10 bags and price GH₵16/bag. Check net profit GH₵60, recorded cost GH₵50/acre, break-even GH₵10/bag and projected profit GH₵60.
- Navigate Home, Reports, Farms and Profile; open crop insights.
- Relaunch and confirm records persist. After an initial online login/load, check cached records in airplane mode and verify queued writes sync after reconnecting. Do not assume first-time login works offline.
- Verify deleting a transaction updates totals and survives a relaunch.
- Use a second account and confirm the first farmer's records are inaccessible.
- Test small screens, large system text, keyboard visibility and slow connectivity.

## Pilot rollout
Start with the planned 10 pilot farmers. Expand only after startup, account access, data ownership and calculations pass on real devices. Collect feedback after each farmer completes a farm/crop/transaction flow.

## Bug report
Record app version/build, Android version/device, steps, expected result, actual result, connection status, and a screenshot. Never include passwords or full personal farm records. The beta coordinator should record severity, owner, status and retest outcome.

## Known limits
Profit figures depend on the income and expenses recorded; projected profit uses expected yield and selling price. This beta does not independently verify market prices. Offline caching does not provide offline account creation. Firebase Authentication, Firestore rules and indexes must be deployed/configured in farmershub-gh-new before a broader beta.

## Signing
Keep the beta keystore outside Git and retain it securely for future updates. The build reads android/key.properties (ignored by Git). CI requires the corresponding private signing values; never commit them. Google Services Android configuration is client configuration, not a server credential.
