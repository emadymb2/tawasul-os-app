# Tawasul School OS Flutter Android app

Offline-first Flutter app for the school core at `https://se.fiksutilitoimisto.fi/`.

## Consoles included

- Teacher console
- Parent console
- Student console

The admin console is intentionally not included.

## Teacher console screens

- Dashboard with today's schedule, attendance register, and school notices
- Lesson preparation assistant
- Lesson summary publisher
- Monthly duty schedule
- Attendance and absence register
- Homework and assignments
- Parent communication
- Staff chat
- Timetable
- Markbook

## Parent console screens

- Arabic dashboard matching the supplied references
- Child selector with per-child attendance and grade summaries
- Children, notifications, messages, and family-data cards
- Today's lessons, grades, school notices, and school contact
- Children list, invoices, and notifications
- Arabic four-item bottom navigation

## API configuration

The app reads configuration from Dart defines:

```bash
flutter build apk --release   --dart-define=TAWASUL_BASE_URL=https://se.fiksutilitoimisto.fi/modules/TawasulCore/api.php/v2   --dart-define=TAWASUL_API_KEY=YOUR_SECURE_KEY
```

Do not commit the API key. For GitHub Actions, add a repository secret named `TAWASUL_API_KEY`.

## Offline-first behavior

The app stores the latest successful console snapshot locally. If the network is unavailable, it opens from the local cache and falls back to bundled demonstration data until live mappings are available.

## Android production build

A GitHub Actions workflow is included at `.github/workflows/flutter-android.yml`. It builds a release APK and uploads it as an artifact.
