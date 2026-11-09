# NEXORA Mobile

Flutter mobile application for **NEXORA**, a PKL (Praktik Kerja Lapangan) logbook and supervision platform.

The mobile application connects to the [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend), a Laravel REST API.

## User roles

| Role | Main capabilities |
| --- | --- |
| Mahasiswa | View PKL placement, submit activity logbooks, attach photos and location, track review status, revise submissions, and view review history |
| Dosen | View assigned students, review logbooks, request revisions, approve or reject submissions, and inspect review history |
| Korlap | Monitor assigned students and logbooks, view progress statistics, complete PKL records, and export reports to PDF or Excel |
| Admin | Manage users and PKL placements, inspect logbooks, and view platform statistics |

## Tech stack

- Flutter and Dart
- Material 3
- Laravel REST API
- HTTP client for API requests
- Shared Preferences for the current local session cache
- Image Picker and Geolocator for logbook attachments
- Path Provider and Open File for exported reports

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Android Studio emulator or an Android device
- A running NEXORA Backend instance

## Run locally

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Start the backend. From the backend repository, run:

   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

3. Run the Flutter app with the API URL:

   **Android Studio emulator** (default):

   ```bash
   flutter run
   ```

   **Physical Android device** (replace the address with the computer's LAN IP):

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
   ```

   **iOS simulator or another local target**:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
   ```

The default API URL is `http://10.0.2.2:8000/api`, which routes Android Emulator traffic to the host computer. Use an HTTPS URL for production builds:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-domain.example/api
```

Do not put credentials, production tokens, or private API keys in Dart source code or commit them to this repository.

## Quality checks

Run these commands before submitting changes:

```bash
flutter analyze
flutter test
```

## Related repository

- [NEXORA Backend](https://github.com/gusti111/NEXORA-Backend)

## Project status

NEXORA is under active development. Features, API contracts, and deployment configuration may change as the mobile and backend repositories evolve.
