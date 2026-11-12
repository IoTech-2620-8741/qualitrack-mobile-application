# QualiTrack Mobile — Architecture

QualiTrack Mobile is a **companion / monitoring & review app** built with Flutter.
It consumes the QualiTrack Cloud REST API (`qualitrack-platform`) and follows
Domain-Driven Design with one folder per Bounded Context.

```
┌──────────────────────────── Presentation ────────────────────────────┐
│ Screens · Widgets · BLoC (events/states) · go_router routes           │
└───────────────┬──────────────────────────────────────────────────────┘
                │ calls the facade of its context (never HTTP)
┌───────────────▼──────────── Application ─────────────────────────────┐
│ <Context>FacadeService (use cases) · <Context>Api (entry point for    │
│ other contexts) · SessionController (app-wide session state)          │
└───────────────┬──────────────────────────────────────────────────────┘
                │ depends on the repository interface
┌───────────────▼──────────── Domain ──────────────────────────────────┐
│ Entities · Value objects · Enums · <Context>Interface · logic mixins  │
│ (no Flutter, no Dio, no storage)                                      │
└───────────────▲──────────────────────────────────────────────────────┘
                │ implements
┌───────────────┴──────────── Infrastructure ──────────────────────────┐
│ Models (JSON → entity) · Remote/local data providers · Repository     │
│ ApiClient (single Dio) · AuthInterceptor · ApiExceptionMapper         │
│ SecureKeyValueStore (flutter_secure_storage) · ApiConfig              │
└──────────────────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Contains | Must not |
|---|---|---|
| **Domain** | Entities (`Equipment`, `DeviationAlert`, `ProductionBatch`…), `LaboratoryId`, `Failure`, `<Context>Interface`, logic mixins and pure functions (`TelemetryAnalysis`, `PasswordPolicy`) | import Flutter widgets, Dio, storage |
| **Application** | `<Context>FacadeService` (orchestrates the interface and applies the logic mixin), `<Context>Api`, `SessionController` | know URLs or JSON |
| **Infrastructure** | `*Model` (extends the entity, adds `fromJson`), `*RemoteDataProvider` / `*LocalDataProvider`, `<Context>Repository`, `ApiClient`, `AuthInterceptor` | leak `DioException` or `Map` to presentation |
| **Presentation** | BLoCs, screens, widgets, labels (enum → text/tone/icon) | call HTTP or hold business rules |

`common/` holds cross-cutting pieces (failures, HTTP client, secure storage,
formatting, localization, theme, reusable widgets). `app/` is the composition
root: dependency injection (`get_it`), router (`go_router`) and the
`MaterialApp`. `command_center/` is a **UI composition module** (application +
presentation only) that aggregates read models from several contexts; it is not
a Bounded Context.

## Dependency rules

Checked by `test/architecture/architecture_test.dart`, which fails the build
when a file breaks one of them.

| Layer | May import |
|---|---|
| `domain` | its own domain and `common/domain`; only `equatable` as a package |
| `application` | domain, application, `common/domain`, `common/application`, and other contexts' `api/index.dart`; no Flutter |
| `infrastructure` | domain, infrastructure, `common/domain`, `common/infrastructure`; no Flutter, BLoC or router |
| `presentation` | application, domain entities, `common/*` except infrastructure, and other contexts' `api/index.dart` |
| `api` | its own application and domain (the context's public entry point; no widgets) |

- A context reaches another one only through `<context>/api/index.dart`.
- `common/` imports no bounded context.
- Only `app/` and `main.dart` may import anything, including `app/` itself.
- When `app/` wires a widget of one context into another (e.g. the panel), it
  passes it in as a parameter instead of letting the context import it.

## Structure of a bounded context

Every context follows the layout of the Flutter DDD guide; `batch` is the
reference. Only the layers a context needs exist (`command_center` has no
domain).

```
<context>/
├── api/index.dart              # public entry point (<Context>Api + exported entities)
├── application/
│   └── <context>_facade_service.dart
├── domain/
│   ├── entities/               # one file per entity or enum
│   ├── interfaces/             # <context>_interface.dart
│   └── logic/                  # <context>_logic.dart mixin, pure rules
├── infrastructure/
│   ├── data_sources/           # <context>_remote_data_provider.dart (+ local)
│   ├── models/                 # extend the entities, add fromJson
│   └── repositories/           # <context>_repository.dart
└── presentation/
    ├── bloc/
    ├── screens/                # *_screen.dart
    └── widgets/
```

One interface, one repository and one facade per context. The facade only
orchestrates: the rules live in the `*Logic` mixin and the data access behind
the interface.

## Public entry points (`api/`)

A context is used by another one only through `api/index.dart`, which exposes a
`*Api` class wrapping the facade and re-exports the entities consumers need. It
never exports widgets: when a context must show something of another one, `app/`
passes it in (see `command_center/presentation/command_center_views.dart`, filled
in by `app/router/command_center_views.dart`).

| Context | Entry point | Used by |
|---|---|---|
| `batch` | `BatchApi` | `command_center` |
| `laboratory` | `LaboratoryApi` | `batch`, `command_center`, `compliance`, `equipment`, `inventory`, `profile`, `reporting`, `tracking` |
| `equipment` | `EquipmentApi` | `command_center`, `compliance`, `reporting`, `tracking` |
| `tracking` | `TelemetryApi` | `command_center`, `equipment` |
| `compliance` | `ComplianceApi` | `batch`, `command_center`, `equipment` |
| `inventory` | `InventoryApi` | `command_center` |
| `subscription` | `SubscriptionApi` | `command_center` |
| `iam` | entities only (`UserRole`, `UserSession`) | `command_center`, `profile` |
| `reporting` | `ReportingApi` | `batch`, `equipment` |

## Adding a feature

For a new read or command in a context (the order of the guide):

1. **Domain:** add the method to `<context>_interface.dart` and, if there is a
   business rule, to the `*Logic` mixin.
2. **Infrastructure:** implement it in the repository and the data provider; add
   or extend the model if the JSON changes.
3. **Application:** add a method to the facade that calls the repository and
   applies the logic. If another context needs it, expose it in the `*Api`.
4. **Presentation:** add the event and state to the BLoC and the widget that
   dispatches it.
5. **Wiring:** nothing new to register unless a class was added to
   `app/dependency_injection/injection.dart`.

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

**Navigation.** The bottom bar has the tabs of the Report (Mobile Style
Guidelines), ordered by importance: Home, Alerts, Telemetry, Batches and More
(alerts right after Home, as what a QA user acts on first). Each tab
is a branch of a `StatefulShellRoute`; `MainShell` builds the bar from the
branches, so the order is defined once, in `app/router/app_router.dart`. More
holds the rest: products, equipment, inventory, reports, subscription (quality
managers), notifications, profile and about. Every section keeps one icon on the
bar, in More, on Home and in its lists (alerts use `report_problem`; the bell is
the notifications). A Home card opens its tab with `go`, or pushes inventory,
which is not a tab; links to a detail use `push`, which keeps the current tab and
adds a back arrow.

**Home.** Four cards, two per row, read by importance top to bottom and left
to right: alerts, telemetry, batches awaiting the QA decision, and inventory
below the minimum stock. They fill the screen without scrolling; on a short
screen each card leaves out its detail instead of shrinking, and only when the
user's larger text does not fit even then the panel scrolls, so the text keeps
the size the user chose. The app is portrait (`AppOrientation`); only the
telemetry history may turn to landscape, through `LandscapeAllowed`.

**Session.** `SplashScreen` → `SessionController.restore()` reads the JWT from the
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
Anything else that reaches a BLoC goes through `Failure.from`, so presentation never
imports infrastructure.

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
with `loadAll` (`common/application/bounded_concurrency.dart`, 4 requests in
flight), the same way QualiTrack Web does.

**Notifications.** `UnreadNotificationsController` keeps the count of the bell
(every 60 s while the app is in foreground and after reading); opening a notice
marks it as read and leads to the alert or the batch.

**Roles.** As in QualiTrack Web: operators and quality managers acknowledge and
resolve alerts (`UserSession.canAttendAlerts`); only quality managers release or
reject batches and see the subscription (`canManageQuality`); auditors only
read. Every action asks for confirmation and the backend remains the authority.

## Localization

English (default) and Spanish. Strings live in `i18n/strings.tsv` and
`dart run tool/generate_i18n.dart` generates `lib/common/presentation/i18n/app_localizations.dart`
(a `LocalizationsDelegate` registered with `flutter_localizations`). A test
verifies both languages define the same keys.

## Dependency injection

`app/dependency_injection/injection.dart` registers configuration, the single
`ApiClient`, data providers, repositories (as their `*Interface`), facades and
`*Api` classes (lazy singletons) and BLoCs (factories; detail BLoCs use
`registerFactoryParam` with the entity id). Only the router resolves BLoCs;
widgets receive them through `BlocProvider`.

## Tests

`test/` mirrors the layers: `domain`, `application`, `infrastructure`,
`presentation` and `widget`. `test/architecture/architecture_test.dart` checks the
dependency rules above on every run, and CI (`.github/workflows/ci.yml`) runs
`flutter analyze` and `flutter test` on every pull request from a `feature/*`
branch into `develop`.
