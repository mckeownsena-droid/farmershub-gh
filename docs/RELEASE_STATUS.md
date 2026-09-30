# Android beta 0.3.0 verification status

## Release-blocking backend issue
The deployed Firebase service allowed a second temporary account to read the first account's farm document during the acceptance check. The temporary records and accounts were removed. Do not distribute to broader beta testers until owner-only rules are deployed and the acceptance check passes.

The repository's firestore.rules already rejects reads/writes from other users. Deploy those exact rules using an authorized Firebase administrator session:

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project farmershub-gh-new
python3 scripts/firebase_acceptance.py
```

Firebase sign-in is an administrator authorization step; email/password sign-in inside the mobile app does not authorize rules deployment.

## Verified so far
- Android launcher, namespace, application ID and Firebase client registration match.
- Ten unit/widget tests passed: profitability, farmer insight, report aggregation, form validation and startup error rendering.
- Static analysis has no errors or warnings; informational style/deprecation notices remain in older app code.
- Firebase email/password test account signup and deletion passed.

Build and Android emulator results will be added after verification completes. A build must not be described as ready for wider testing while the backend ownership check fails.
