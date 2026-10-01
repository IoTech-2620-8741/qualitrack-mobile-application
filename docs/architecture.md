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
| `iam` | Identity & Access Management | Sign in, session, onboarding check, profile, logout |
| `subscription` | Payments & Subscriptions | Active plan, history, payments (read-only) |
| `laboratory` | Laboratory Management | Laboratory info, product catalog (read-only) |
| `inventory` | Inventory Management | Materials, receipts, movements (read-only) |
| `equipment` | Equipment Management | Equipment, maintenance, BPM limits (read-only) |
| `tracking` | Tracking & Telemetry | Status, latest measurements, history, polling (read-only) |
| `batch` | Product Batch Management | Batches, raw material usage, release/reject of existing batches |
| `compliance` | Compliance & Alerting | Alerts, acknowledge/resolve, compliance events |
| `reporting` | Reporting & Audit | KPI dashboard, report history, trends, audit logs (read-only) |

## Key flows

**Session.** `SplashPage` → `SessionController.restore()` reads the JWT from the
keystore, discards it if `exp` has passed, and calls `GET /users/me/onboarding`.
Status `authenticated | setupRequired | unauthenticated` drives the
`go_router` redirect (`refreshListenable`). On any authenticated 401 the
`AuthInterceptor` calls `SessionController.expire()` once (re-entrancy guard);
the router then shows Sign In with a "session expired" banner.

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

**Live telemetry.** `TelemetryDashboardBloc` polls status + latest measurements
every 15 s and the last 24 h history every 4th tick. Polling pauses when the app
goes to background and the timer is cancelled in `close()`. Chart windows
(15 min / 1 h / 6 h / 24 h) are offered only if real timestamps span them. No
WebSockets are simulated and the app never POSTs telemetry.

**Review actions.** Acknowledge/Resolve and Release/Reject are shown only to
`ROLE_QA_MANAGER` / `ROLE_ADMIN` (`UserSession.canReview`) and always ask for
confirmation. The backend remains the authority (see gaps in
`mobile-api-mapping.md`).

## Localization

English (default) and Spanish. Strings live in `l10n/strings.tsv` and
`tool/generate_l10n.py` generates `lib/shared/presentation/l10n/app_localizations.dart`
(a `LocalizationsDelegate` registered with `flutter_localizations`). A test
verifies both languages define the same keys.

## Dependency injection

`app/dependency_injection/injection.dart` registers configuration, the single
`ApiClient`, data sources, repositories, use cases (lazy singletons) and BLoCs
(factories; detail BLoCs use `registerFactoryParam` with the entity id). Only
the router resolves BLoCs; widgets receive them through `BlocProvider`.
