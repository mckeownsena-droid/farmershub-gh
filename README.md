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

## Firebase configuration required before running

This repository intentionally does not contain private Firebase platform configuration files. Use the existing Firebase project (`farmershub-gh-new`) and add the generated configuration for the platform you want to run:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Web/Desktop: run FlutterFire CLI to generate `lib/firebase_options.dart`, then initialize Firebase with `DefaultFirebaseOptions.currentPlatform`.

For Android/iOS, the simplest path is to create a normal Flutter project shell, copy this repository's `lib/`, `pubspec.yaml`, and Firebase files into it, then run `flutter pub get`.

## Firebase console requirements

1. Enable **Email/Password** under Firebase Authentication.
2. Create **Cloud Firestore**.
3. Deploy `firestore.rules`.
4. Add the Android/iOS/Web app registration and platform config files.

## Development branch

The active MVP build is developed on `chatgpt/mvp-build` until it is verified and merged into `main`.
