# FarmersHub GH

FarmersHub GH is a farm finance and management app for farmers in Ghana.

## Current MVP

- Email/password authentication
- Password reset
- Farmer profile with phone number
- Dashboard with total balance, income and expenses
- Add income/expense transactions
- Link transactions to a farm
- Payment method tracking (Cash, Mobile Money, Bank Transfer)
- Recent transactions with delete support
- Reports and expense-category summaries
- Farm registration
- Crop records per farm
- Firebase Authentication and Cloud Firestore backend
- User-scoped Firestore security rules

Primary brand color: `#2E7D32`.

## Firestore collections

### `users`
- `uid` string
- `display_name` string
- `email` string
- `phone_number` string
- `photo_url` string
- `created_time` timestamp

### `farms`
- `user_id` string
- `name` string
- `location` string
- `farm_type` string
- `size_acres` number
- `created_time` timestamp

### `transactions`
- `user_id` string
- `farm_id` string
- `farm_name` string
- `type` string (`Income` or `Expense`)
- `category` string
- `amount` number
- `payment_method` string
- `notes` string
- `date` timestamp
- `created_time` timestamp

### `crops`
- `user_id` string
- `farm_id` string
- `farm_name` string
- `crop_name` string
- `acreage` number
- `planting_date` timestamp
- `status` string
- `created_time` timestamp

## Android development and release

The Android shell is committed. Use Flutter **3.35.0**, Java 17 and Android SDK 36. The application ID, namespace and launcher class are consistently `com.mycompany.farmershubghmvp`, matching the existing Firebase Android registration in `farmershub-gh-new`.

```bash
flutter pub get
python3 scripts/check_android.py
flutter analyze --no-fatal-infos
flutter test
flutter run
```

For a signed beta release, securely restore the retained beta keystore and create ignored `android/key.properties`:

```properties
storeFile=/absolute/path/to/farmershub-beta.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyPassword=YOUR_PRIVATE_PASSWORD
keyAlias=farmershub-beta
```

```bash
flutter build apk --release
bash scripts/android_smoke.sh build/app/outputs/flutter-apk/app-release.apk
```

The release APK is `build/app/outputs/flutter-apk/app-release.apk`. Release builds require private signing configuration and do not fall back to debug signing. Keep the same keystore for future beta updates. The Android beta verification workflow builds and emulator-tests a release candidate with a disposable CI signer. Re-sign it privately with the retained beta key before distribution. See docs/RELEASE_STATUS.md for tested behavior and remaining pilot acceptance.

See [beta testing](docs/BETA_TESTING.md) for rollout checks and [crash investigation](docs/ANDROID_CRASH.md) for the launcher defect. `python3 scripts/firebase_acceptance.py` checks the deployed Auth/Firestore service with temporary accounts and deletes its test records afterward.

Android/iOS client Firebase configuration files are present. They identify the public Firebase app and are not server admin credentials. For iOS/Web configuration and testing, use the matching app registration; Android is the verified target for this milestone.

## Firebase console requirements

1. Enable **Email/Password** under Firebase Authentication.
2. Create **Cloud Firestore**.
3. Deploy `firestore.rules`.
4. Add the Android/iOS/Web app registration and platform config files.

## Development branch

The active MVP build is developed on `chatgpt/mvp-build` until it is verified and merged into `main`.
