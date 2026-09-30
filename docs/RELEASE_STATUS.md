# Android beta 0.3.0 verification status

Verified application commit: eb61be3cf8f99ad3458fe8cca17998f377fef83f.

## Completed
- Full Android project committed; launcher class, namespace, application ID and Firebase registration match.
- All ten Flutter unit/widget tests passed; analysis has no errors or warnings.
- Release build installed and cold-launched on API30 x86_64 emulator, survived startup and relaunched. Login screenshot inspected; captured startup log scanned without matching fatal errors.
- Evidence: https://github.com/mckeownsena-droid/farmershub-gh/actions/runs/36744320141
- Final release APK privately re-signed with dedicated retained 3072-bit beta key. v2/v3 signature verified; every application ZIP entry compared unchanged after signing.
- APK SHA256: 58ef37f17f0c11ef63b2208d41e061d4126c9712b021b633bea2e16954483649
- Certificate SHA256: 84603911aa758c1d473889a1f50f3b02638f33a881a3a444b052b2669f9a5da1
- APK, private signing backup, handover and emulator evidence saved for project owner.

## Firebase fix
On 30 September 2026, deployed the repository-equivalent owner-only rules to farmershub-gh-new through an authenticated administrator session. Previous rules granted every signed-in account access to all documents. Temporary two-account checks now pass for owner writes/reads and cross-account read rejection in farms, crops and transactions. All temporary records/accounts cleaned up.

Created the required crops Collection composite index: user_id ASC, farm_id ASC. Firebase console confirms the index is Enabled.

## Remaining acceptance
Use docs/BETA_TESTING.md for the controlled ten-farmer pilot. Full farm/crop/transaction UI flows, offline reconnection, password reset and physical-device coverage are not yet verified. The final signing container was validated, but the emulator installation used the same release application bytes with a disposable CI signer. Do not describe these checks as a completed broad-beta acceptance.

CI release artifacts use a disposable signer and must be privately re-signed with the retained stable beta key before distribution. Never publish the private signing backup or passwords.
