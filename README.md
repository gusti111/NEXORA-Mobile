# NEXORA Mobile

Flutter application for **NEXORA**, a role-based PKL (Praktik Kerja Lapangan) logbook and supervision platform.

This repository contains the mobile client. The Laravel API is maintained separately in [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend).

## Product scope

NEXORA supports four user roles:

| Role | Main capabilities |
| --- | --- |
| **Mahasiswa** | View PKL placement, create daily logbooks, attach activity photos and optional GPS coordinates, monitor review status, revise requested submissions, and read review history. |
| **Dosen** | View assigned students and their submissions, approve or reject logbooks, request revisions with comments, and inspect review history. |
| **Korlap** | Monitor assigned students and logbooks, view progress statistics, complete PKL placements when requirements are met, and export reports to PDF or Excel. |
| **Admin** | Manage user accounts and PKL placements, inspect submitted logbooks, reset passwords, and view platform statistics. |

## Architecture

```text
Flutter application
  ├── Login and role-based dashboards
  ├── Feature screens (Mahasiswa / Dosen / Korlap / Admin)
  ├── ApiService (REST API requests)
  └── SessionTokenStore (secure access-token storage)
           │
           │ HTTPS in production
           ▼
Laravel REST API (NEXORA Backend)
  ├── Laravel Sanctum authentication
  ├── Role and active-account middleware
  ├── PKL and logbook workflows
  └── MySQL / SQLite database and file storage
```

## Technology

- Flutter and Dart
- Material 3
- Laravel REST API with Sanctum bearer tokens
- `http` for REST and multipart requests
- `flutter_secure_storage` for the access token
- `shared_preferences` for non-secret cached profile and local inactivity timestamp
- `image_picker` and `geolocator` for logbook attachments
- `path_provider` and `open_filex` for exported reports
- `sqflite` for the offline cache/outbox and `uuid` for stable submission keys

## Requirements

- Flutter SDK with Dart compatible with `pubspec.yaml` (`^3.11.4`).
- Android Studio / Android SDK or Xcode for iOS builds.
- Android API 23 or newer (required by the configured secure-storage plugin).
- A running NEXORA Backend API.

## Local development

### 1. Install mobile dependencies

```bash
flutter pub get
```

Commit the regenerated `pubspec.lock` after adding or changing dependencies so application builds remain reproducible.

### 2. Start the backend

Follow the setup instructions in [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend).

On Windows, the backend repository provides a guarded local-staging bootstrap:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\start-local-staging.ps1
```

This uses a local SQLite database and dummy student/lecturer/coordinator accounts. It refuses to run unless `APP_ENV=local` and `DB_CONNECTION=sqlite`.

For other operating systems, from the backend repository configure a local SQLite `.env`, run migrations and the local-only demo seeder, then start Laravel:

```bash
php artisan migrate
php artisan db:seed --class="Database\\Seeders\\StagingDemoSeeder"
php artisan serve --host=0.0.0.0 --port=8000
```

### 3. Configure the API URL

The API base URL is injected at build/run time using `API_BASE_URL`.

| Target | Example |
| --- | --- |
| Android Studio emulator | Default: `http://10.0.2.2:8000/api` |
| Physical Android device | `http://192.168.1.10:8000/api` (replace with the development computer's LAN IP) |
| iOS simulator | Use a reachable HTTPS endpoint or a local HTTPS tunnel; iOS App Transport Security blocks arbitrary cleartext HTTP by default. |

Android cleartext traffic is enabled only by the debug manifest for local development. The main/release manifest does not opt in to cleartext traffic.

Example for a physical Android device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Example production build:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api
```

Use a real HTTPS API domain for release builds. Do not put credentials, bearer tokens, database passwords, or private API keys in Dart source code, `--dart-define` values, or Git.

## Authentication and session handling

- Login accepts an email address or username plus password.
- The Sanctum bearer token is stored through `flutter_secure_storage` (Android encrypted storage / Apple Keychain).
- Existing installations migrate a legacy token from `SharedPreferences` into secure storage on the next token read; the plaintext preference is removed after a successful secure write.
- Cached profile data and the local background timestamp remain in `SharedPreferences`; they are not authentication credentials.
- The app validates the current token against `GET /api/user` on startup and when returning to the foreground.
- An HTTP `401` or an inactive-account response from the session endpoint clears the local session and returns the user to login.
- A network failure does not automatically delete the cached session; dashboards can show their connection-error state instead.
- The app enforces a five-minute background inactivity timeout. The backend also has its own Sanctum token expiration policy.
- Logbook photos are loaded from an authenticated private endpoint with the bearer token; the client does not construct public `/storage` URLs or hardcode a LAN IP.
- Database-backed in-app notifications are available to all four roles; the inbox supports unread counts and mark-read actions.
- Logout attempts to revoke the current token using `POST /api/logout`, then clears the local session even when the API is unreachable.

Android secure-storage setup disables automatic app backup to avoid restoring encrypted preferences without the corresponding device key. The release manifest does not enable cleartext HTTP.

## API integration

The mobile client uses the `/api` prefix. Important endpoints include:

| Area | Endpoints |
| --- | --- |
| Authentication | `POST /login`, `POST /logout`, `GET /user` |
| Mahasiswa | `GET /pkls`, `GET /logbooks`, `POST /logbooks`, `PUT /logbooks/{id}/resubmit`, `GET /logbooks/statistics`, `GET /logbooks/{id}/history` |
| Dosen | `GET /dosen/logbooks`, `GET /dosen/mahasiswa`, `PATCH /dosen/logbooks/{id}/review` |
| Korlap | `GET /korlap/logbooks`, `GET /korlap/statistics`, `GET /korlap/mahasiswa`, `PUT /korlap/pkls/{id}/complete`, report exports |
| Admin | `GET /admin/statistics`, user management, PKL management, and logbook oversight |

See `lib/services/api_service.dart` and `routes/api.php` in the backend repository for the current request/response contract.

For multipart logbook resubmission, the Flutter client sends `POST` with Laravel's `_method=PUT` field; the effective backend route remains `PUT /api/logbooks/{id}/resubmit`.

## Offline logbook drafts and synchronization

The student logbook flow uses a local SQLite outbox:

1. The app stores the logbook fields under the signed-in user ID before attempting network submission.
2. A selected photo is copied into the app's documents directory so it remains available after the image picker cache is cleared.
3. Each draft receives a stable UUID. The same UUID is sent as `idempotency_key` every time the draft is retried.
4. The backend returns the original record on a replay instead of creating a duplicate.
5. Successful drafts are removed from the outbox and their copied photo is deleted. Network errors, 401/403 authorization responses, timeouts, throttling, and 5xx responses remain pending for recovery; other permanent 4xx responses are marked failed and can be removed from the history screen after review.
6. The app shows cached PKL/logbook data when the server cannot be reached.

Synchronization is attempted after login, when the app resumes, and manually from the student logbook history screen. This phase does **not** run a background worker while the application is fully terminated, and it does not use a connectivity signal as proof that the internet is reachable; the API request itself determines whether synchronization succeeds.

The local queue is scoped by the current account ID. Access tokens are not stored in SQLite. Queue text and copied evidence files are stored in the app's private documents area, but this phase does not add separate application-level encryption for those draft contents. Device-level file protection and a retention policy should be reviewed before handling highly sensitive evidence.

## In-app notifications

The mobile inbox consumes the backend database notification endpoints:

- `GET /api/notifications` returns the latest 50 notifications and unread count.
- `GET /api/notifications/unread-count` returns the current unread count.
- `PATCH /api/notifications/{id}/read` marks one of the current user's notifications as read.
- `PATCH /api/notifications/read-all` marks all of the current user's notifications as read.

The dashboard exposes the inbox for Mahasiswa, Dosen, Korlap, and Admin. This is an in-app inbox; Firebase Cloud Messaging / Apple Push Notification delivery is not configured in this phase.

## Backend staging integration

Use the [NEXORA Backend Phase 2 staging runbook](https://github.com/gusti111/NEXORA-Backend/blob/main/docs/STAGING_INTEGRATION_RUNBOOK.md) and [Postman collection](https://github.com/gusti111/NEXORA-Backend/blob/main/postman/NEXORA-Phase-2-Staging.postman_collection.json) to validate the live Mobile–Backend contract. Configure the APK with `--dart-define=API_BASE_URL=https://STAGING-HOST/api`. A real staging integration has not yet been marked passed because no staging host or deployment environment is configured in the repositories.

## Project structure

```text
lib/
├── main.dart
├── services/
│   ├── api_service.dart
│   ├── session_token_store.dart
│   ├── offline_logbook_store.dart
│   └── offline_logbook_service.dart
├── widgets/
│   └── secure_logbook_image.dart
├── screens/
│   ├── notification_center_screen.dart
│   ├── admin/
│   ├── dosen/
│   ├── korlap/
│   └── mahasiswa/

test/
├── support/
├── api_service_logbook_test.dart
├── offline_logbook_service_test.dart
├── offline_logbook_store_test.dart
├── session_token_store_test.dart
└── widget_test.dart
```

Feature screens are grouped by user role. Shared network and session concerns belong in `lib/services/` rather than being duplicated in screens.

## Quality checks

Run these commands before opening a pull request:

```bash
flutter pub get
flutter analyze
flutter test --reporter expanded
```

On Linux, install the SQLite development library before running the FFI-based outbox tests:

```bash
sudo apt-get install libsqlite3-dev
```

GitHub Actions runs the Flutter analyzer and test suite on pushes to `main`, `fix/**`, and `feat/**`, and on pull requests targeting `main` or `fix/**`.

## Release readiness notes

- Configure a production API URL with HTTPS.
- Configure a dedicated Android release keystore before Play Store publication. The current Gradle release configuration still uses the debug signing key and is for development/testing only.
- Test secure-storage migration on an installed build that already has a legacy session.
- Validate camera, location, file export, and app lifecycle behavior on physical devices.
- Keep `pubspec.lock` committed after dependency resolution.
- Review offline queue retention, app-private photo retention, and device-loss behavior before production use.

## Related repository

- [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend)

## Project status

NEXORA is under active development. API contracts, UI behavior, and deployment configuration may evolve as the mobile and backend repositories progress.
