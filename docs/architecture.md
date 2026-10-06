# QualiTrack Mobile — Architecture

QualiTrack Mobile is a **companion / monitoring & review app** built with Flutter.
It consumes the QualiTrack Cloud REST API (`qualitrack-platform`) and follows
Domain-Driven Design with one folder per Bounded Context.

```
┌──────────────────────────── Presentation ────────────────────────────┐
│ Pages · Widgets · BLoC (events/states) · go_router routes             │
└───────────────┬──────────────────────────────────────────────────────┘
                │ calls use cases (never HTTP)
┌───────────────▼──────────── Application ─────────────────────────────┐
│ Queries (GetAlerts, GetTelemetryHistory…) · Commands (AcknowledgeAlert,│
│ ResolveAlert, ReleaseExistingBatch, RejectExistingBatch, SignIn…)     │
│ SessionController (app-wide session state)                            │
└───────────────┬──────────────────────────────────────────────────────┘
                │ depends on repository interfaces
┌───────────────▼──────────── Domain ──────────────────────────────────┐
│ Entities · Value objects · Enums · Repository interfaces · pure rules │
│ (no Flutter, no Dio, no storage)                                      │
└───────────────▲──────────────────────────────────────────────────────┘
                │ implements
┌───────────────┴──────────── Infrastructure ──────────────────────────┐
│ DTOs (JSON → DTO → Entity) · Remote data sources · Repository impls   │
│ ApiClient (single Dio) · AuthInterceptor · ApiExceptionMapper         │
│ SecureKeyValueStore (flutter_secure_storage) · ApiConfig              │
└──────────────────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Contains | Must not |
|---|---|---|
| **Domain** | `Equipment`, `DeviationAlert`, `ProductionBatch`, `InventoryMaterial`, `TelemetryAnalysis`, `LaboratoryId`, `Failure`, repository interfaces | import Flutter widgets, Dio, storage |
| **Application** | Use cases (callable classes), `SessionController`, read models such as `BillingSummary` | know URLs or JSON |
| **Infrastructure** | `*Dto.toDomain()`, `*RemoteDataSource`, `*RepositoryImpl`, `ApiClient`, `AuthInterceptor`, `SecureSessionRepository` | leak `DioException` or `Map` to presentation |
| **Presentation** | BLoCs, pages, widgets, labels (enum → text/tone/icon) | call HTTP or hold business rules |

`shared/` holds cross-cutting pieces (failures, HTTP client, secure storage,
formatting, localization, reusable widgets). `app/` is the composition root:
theme, dependency injection (`get_it`), router (`go_router`) and the
`MaterialApp`. `command_center/` is a **UI composition module** (application +
presentation only) that aggregates read models from several contexts; it is not
a Bounded Context.

## Bounded Contexts

| Folder | Context | Mobile scope |
|---|---|---|
| `iam` | Identity & Access Management | Sign in, session, onboarding check, forced and voluntary password change, logout |
| `subscription` | Payments & Subscriptions | Current plan, history, payments (read-only, quality managers only) |
| `laboratory` | Laboratory Management | Laboratory, environments, staff names, product catalog per environment (read-only) |
| `inventory` | Inventory Management | Raw materials per environment, lots, movements, batches that used them (read-only) |
| `equipment` | Equipment Management | Equipment and IoT role, maintenance, BPM limits (read-only) |
| `tracking` | Tracking & Telemetry | Connection, readings per environment or container monitor, profile ranges, automatic actions, polling (read-only) |
| `batch` | Product Batch Management | Batches, traceability, release (digital signature) and rejection |
| `compliance` | Compliance & Alerting | Alerts per environment, acknowledge/resolve, compliance events, in-app notifications and preferences |
| `reporting` | Reporting & Audit | Measurement summary and deviation indicators per period, report history, audit logs (read-only) |
| `profile` | Profile | Personal data, photo |

## Key flows

**Session.** `SplashPage` → `SessionController.restore()` reads the JWT from the
keystore, discards it if `exp` has passed, and calls `GET /users/me/onboarding`.
Status `authenticated | passwordChangeRequired | setupRequired | unauthenticated` drives the
`go_router` redirect (`refreshListenable`). On any authenticated 401 the
`AuthInterceptor` calls `SessionController.expire()` once (re-entrancy guard);
the router then shows Sign In with a "session expired" banner.

**Temporary password.** Staff members registered by the quality manager sign in
with a temporary password; while `nextStep` is `PASSWORD_CHANGE` the router only
shows the password change screen. After `POST /users/me/password-changes` the
session is re-evaluated.

**No fallback IDs.** Every laboratory scoped call obtains the id through
`SessionController.requireLaboratoryId()`, which throws
`MissingLaboratoryFailure` instead of defaulting. Accounts without laboratory or
active subscription are sent to "Complete your setup in QualiTrack Web".

**Errors.** `ApiClient` converts everything into a sealed `Failure`
(`NetworkFailure`, `TimeoutFailure`, `BadRequestFailure`, `UnauthorizedFailure`,
`ForbiddenFailure`, `OnboardingRequiredFailure`, `NotFoundFailure`,
`ConflictFailure`, `ServerFailure`, `ParsingFailure`…). Presentation maps them to
localized text via `failureMessage()`; backend validation details are appended
so rejected transitions (e.g. "Rejected batches cannot be released") are visible.

**Screen states.** Read-only BLoCs use `RemoteState<T>`
(`initial → loading → success | empty | failure`, plus `refreshing`). Detail
screens load secondary sections independently (`Section<T>`) so one failing
endpoint does not hide the rest.

**Live telemetry.** Only IoT devices located in an environment report telemetry
(the environmental device of the environment and its container monitors).
`TelemetryDashboardBloc` loads the last 24 hours once; then every 15 s it reads
the connection and only the readings of the last minutes, merged by id, and
the automatic actions every 4th tick. Polling pauses when the app goes to
background and the timer is cancelled in `close()`. Chart windows
(15 min / 1 h / 6 h / 24 h) are offered only if real timestamps span them; the
normal and critical ranges of the profile are drawn as dashed lines. The app
never POSTs telemetry.

**Environments.** Several resources are exposed per environment (alerts,
materials, products, deviation indicators). Laboratory-wide screens add them up
with `loadAll` (`shared/application/bounded_concurrency.dart`, 4 requests in
flight), the same way QualiTrack Web does.

**Notifications.** `UnreadNotificationsController` keeps the count of the bell
(every 60 s while the app is in foreground and after reading); opening a notice
marks it as read and leads to the alert or the batch.

**Roles.** As in QualiTrack Web: operators and quality managers acknowledge and
resolve alerts (`UserSession.canAttendAlerts`); only quality managers release or
reject batches and see the subscription (`canManageQuality`); auditors only
read. Every action asks for confirmation and the backend remains the authority.

## Localization

English (default) and Spanish. Strings live in `l10n/strings.tsv` and
`dart run tool/generate_l10n.dart` generates `lib/shared/presentation/l10n/app_localizations.dart`
(a `LocalizationsDelegate` registered with `flutter_localizations`). A test
verifies both languages define the same keys.

## Dependency injection

`app/dependency_injection/injection.dart` registers configuration, the single
`ApiClient`, data sources, repositories, use cases (lazy singletons) and BLoCs
(factories; detail BLoCs use `registerFactoryParam` with the entity id). Only
the router resolves BLoCs; widgets receive them through `BlocProvider`.
