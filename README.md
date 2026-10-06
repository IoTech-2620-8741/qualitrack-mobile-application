# QualiTrack Mobile

Official Flutter companion app of **QualiTrack**, the pharmaceutical Quality
Management System by IoTech. It lets quality managers, operators and auditors
monitor and review — from their phone — what is registered and configured in
QualiTrack Web: the conditions of environments and containers, deviation alerts,
production batches, inventory, equipment, indicators and the subscription.

> Creation and configuration (laboratories, products, materials, receipts,
> equipment, sensors, limits, batches, users, plans, checkout) stay in
> **QualiTrack Web**. The app never publishes telemetry.

## Features

- Secure sign-in (JWT in Keychain/Keystore), session restore, expiry handling and logout
- Forced password change on the first sign-in of staff members (temporary password)
- Control panel with the same cards as the Web dashboard (equipment, batches in progress, open alerts, low stock, subscription for quality managers)
- Monitoring of environments and containers: connection, readings with their state, normal and critical ranges, deviations, automatic actions, live polling (15 s); reading history of up to 31 days
- Alerts of every environment with filters and detail; **acknowledge** and **resolve** (operators and quality managers)
- In-app notifications (bell) and notification preferences
- Production batches with traceability (raw materials, equipment, staff, container) and **release** with digital signature or **rejection** (quality managers)
- Inventory per environment (stock, lots and expiry, movements, batches that used each material)
- Equipment (IoT role, connection, BPM limits, maintenance, deviation indicators, audit log)
- Product catalog, measurement summary and deviation indicators per period, report history, subscription
- Profile: personal data, photo and password
- Auditors only read
- English / Spanish, accessible badges (icon + text), responsive from 360×640

## Architecture

Domain-Driven Design, one module per Bounded Context, each with
`domain / application / infrastructure / presentation` layers. State management
with BLoC, DI with get_it, navigation with go_router, HTTP with a single Dio
client. See [`docs/architecture.md`](docs/architecture.md) and the endpoint
mapping in [`docs/mobile-api-mapping.md`](docs/mobile-api-mapping.md). The
initial analysis is in [`docs/analysis.md`](docs/analysis.md).

```
lib/
├── main.dart
├── app/            # composition root: theme, router, DI, MaterialApp
├── shared/         # failures, ApiClient, secure storage, l10n, widgets
├── iam/            # Identity & Access Management
├── laboratory/     # Laboratory Management (lab, products)
├── equipment/      # Equipment Management
├── tracking/       # Tracking & Telemetry
├── compliance/     # Compliance & Alerting
├── batch/          # Product Batch Management
├── inventory/      # Inventory Management
├── reporting/      # Reporting & Audit
├── subscription/   # Payments & Subscriptions
├── profile/        # Profile (personal data and photo)
└── command_center/ # UI composition of the home screen
```

## Requirements

- Flutter stable 3.29 or newer (Dart ≥ 3.7); verified with Flutter 3.44 / Dart 3.12
- Android Studio / Android SDK (or Xcode for iOS)
- A running `qualitrack-platform` backend (v0.13.2 or newer)

## Installation

```bash
git clone https://github.com/IoTech-2620-8741/qualitrack-mobile-application.git
cd qualitrack-mobile-application
flutter create --org com.iotech --project-name qualitrack_mobile --platforms android,ios .   # only the first time, creates platform folders
flutter pub get
```

## API configuration

The backend URL is injected at build time; there is no hardcoded default.

| Target | Command |
|---|---|
| Android emulator (backend on your PC) | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| Physical device (same Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<your-PC-IP>:8080` |
| Deployed backend | `flutter run --dart-define=API_BASE_URL=https://<host>` |

`/api/v1` is appended automatically. For plain `http://` on Android 9+, allow
cleartext traffic for development (`android:usesCleartextTraffic="true"` in the
debug manifest) or use HTTPS.

## Tests and quality

```bash
dart format .
flutter analyze
flutter test
```

On Windows you can run everything at once and keep a log in `tool/logs/verify.log`:

```powershell
powershell -ExecutionPolicy Bypass -File tool\verify.ps1
```

Localized strings are edited in `l10n/strings.tsv`, then regenerated with
`dart run tool/generate_l10n.dart`.

## Build APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<host>
```

The APK is generated in `build/app/outputs/flutter-apk/app-release.apk` and can
be distributed with Firebase App Distribution. Notifications are shown inside
the app (bell); push notifications with Firebase are pending.
