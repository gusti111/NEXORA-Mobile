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

Follow the setup instructions in [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend). For local Android emulator development, start Laravel so it listens on the host network interface:

```bash
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
- Logout attempts to revoke the current token using `POST /api/logout`, then clears the local session even when the API is unreachable.

Android secure-storage setup disables automatic app backup to avoid restoring encrypted preferences without the corresponding device key. The release manifest does not enable cleartext HTTP.

## API integration

The mobile client uses the `/api` prefix. Important endpoints include:

| Area | Endpoints |
| --- | --- |
| Authentication | `POST /login`, `POST /logout`, `GET /user` |
| Mahasiswa | `GET /pkls`, `GET /logbooks`, `POST /logbooks`, `POST /logbooks/{id}/resubmit`, `GET /logbooks/statistics`, `GET /logbooks/{id}/history` |
| Dosen | `GET /dosen/logbooks`, `GET /dosen/mahasiswa`, `PATCH /dosen/logbooks/{id}/review` |
| Korlap | `GET /korlap/logbooks`, `GET /korlap/statistics`, `GET /korlap/mahasiswa`, `PUT /korlap/pkls/{id}/complete`, report exports |
| Admin | `GET /admin/statistics`, user management, PKL management, and logbook oversight |

See `lib/services/api_service.dart` and `routes/api.php` in the backend repository for the current request/response contract.

## Project structure

```text
lib/
├── main.dart
├── services/
│   ├── api_service.dart
│   └── session_token_store.dart
└── screens/
    ├── admin/
    ├── dosen/
    ├── korlap/
    └── mahasiswa/

test/
├── support/
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

GitHub Actions runs the Flutter analyzer and test suite on pushes to `main` / `fix/**` and on pull requests targeting `main`.

## Release readiness notes

- Configure a production API URL with HTTPS.
- Configure a dedicated Android release keystore before Play Store publication. The current Gradle release configuration still uses the debug signing key and is for development/testing only.
- Test secure-storage migration on an installed build that already has a legacy session.
- Validate camera, location, file export, and app lifecycle behavior on physical devices.
- Refresh and commit `pubspec.lock` after dependency resolution.

## Related repository

- [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend)

## Project status

NEXORA is under active development. API contracts, UI behavior, and deployment configuration may evolve as the mobile and backend repositories progress.
