# QualiTrack Mobile — Fase de análisis (Etapa 1)

Fecha: 2026-09-16 · Fuentes revisadas:

- `qualitrack-platform` (Spring Boot, rama `develop` @ `923048a`): 35 controllers REST, 832 clases Java.
- `qualitrack-web-app` (Angular 21, rama `develop` @ `feaba0d`): 10 módulos DDD con stores basados en signals.
- `QualiTrack Movik - IOT.pdf`: 24 páginas de mockups móviles.
- Referencias de estructura Flutter: Veyra-Mobile-Application y restock-mobile-application (sólo organización; no se reutiliza dominio ni código).

## 1. Resumen de hallazgos

### Backend (fuente de verdad)
- **Bounded Contexts reales** (paquetes): `iam`, `subscription`, `laboratory`, `inventory`, `equipment`, `tracking`, `batch`, `ca` (Compliance & Alerting), `ra` (Reporting & Audit). No existe “Environmental Control”.
- **Auth**: JWT stateless. `POST /api/v1/authentication/sign-in` → `AuthenticatedUserResource {id, username, token, roles[], laboratoryId}`. Expira en 7 días; el token trae el claim `exp`.
- **Multi-tenant**: un interceptor valida que todo `laboratoryId/labId/equipmentId/batchId/alertId/...` pertenezca al laboratorio del usuario (403 `ACCESS_DENIED`).
- **Onboarding**: si la suscripción no está `ACTIVE` o no hay laboratorio, todos los endpoints operativos devuelven 403 `ONBOARDING_REQUIRED` con `nextStep` (`SUBSCRIPTION` | `LABORATORY`). Mobile debe detectarlo y remitir a Web.
- **Roles**: `ROLE_ADMIN`, `ROLE_QA_MANAGER`, `ROLE_LAB_OPERATOR`. Sólo Inventory (revisión de recepciones, importación legacy) y asignación de roles usan autorización por rol. Release/Reject de lote y Acknowledge/Resolve de alertas **no** tienen restricción de rol en el servidor (ver brechas en `mobile-api-mapping.md`).
- **Tracking**: GET de mediciones, estado e historial (con `from`/`to`). Si no hay estado registrado, el backend responde un estado sintético `OFFLINE, isOnline=false`. Timestamps son strings.
- **Compliance**: alertas por equipo o por lote con filtros `status`/`severity`; detalle por ID; `PATCH /deviation-alerts/{id}` con `{status, performedBy, resolutionNotes}` (`performedBy` debe ser el usuario autenticado; RESOLVED exige notas).
- **Batch**: lista por `labId`, detalle, uso de materias primas, `PATCH /batches/{id}` para `RELEASED` (`releaseDate`, `notes` obligatorios) o `REJECTED` (`rejectionDate`, `reason` obligatorios). El agregado impide release de rechazados y reject de liberados.
- **Inventory**: catálogo con `usableStock`, `physicalStock`, `minimumStock`; recepciones (`QUARANTINED/RELEASED/OBSERVED/REJECTED`, `usable`, `availability`) y movimientos auditados.
- **Reporting**: KPI dashboard (404 si no se ha calculado), historial de reportes, tendencias y audit logs.
- **Subscription**: suscripción activa, resumen de facturación, pagos, planes.
- **Sin paginación, sin WebSockets, sin push notifications / Firebase** en el backend.

### Web (referencia de consumo y diseño)
- Módulos: `iam, laboratory, inventory, equipment, tracking, batch, ca, ra, subscription, shared`, cada uno con `domain/model`, `application/*.store.ts`, `infrastructure/*-api-endpoint.ts + assembler + response`, `presentation/views`.
- Sesión en `localStorage` (token, roles, laboratoryId) + `iam-interceptor` (Bearer) + guards `iamGuard`/`onboardingGuard`.
- `DashboardStore` compone laboratorio, inventario, lotes, equipos, alertas (agregadas por equipo con concurrencia 4), mediciones y suscripción; stock bajo = `usableStock < minimumStock`.
- Inventory oculta la revisión si el usuario no es `ROLE_ADMIN`/`ROLE_QA_MANAGER`.
- Fechas de historial enviadas con `toISOString()`. Release form usa fecha `yyyy-MM-dd` y notas (mín. 10 caracteres en UI).
- i18n `en_US` / `es_419` con ngx-translate.
- Paleta: primario teal `#148F77` (hover `#107562`), azul marino `#1A3A5C`, gris `#5F6368/#64748B`, fondo `#F4F6F9/#F8FAFC`, crítico `#B91C1C/#C53030`, advertencia `#B45309/#FEF3C7`, éxito `#1E7E34/#E6F4EA`; radios 8/12 px; Roboto.
- Mockups: teal `#0E8066`/`#0D9488`, héroe `#0B4744`, texto `#1A3353`/`#334155`, alertas `#EF4444`, warning `#F59E0B`, info `#2563EB`.

## 2. Revisión de mockups

| Pág. | Pantalla | Decisión |
|---|---|---|
| 1 | Pharmaceutical Product Catalog | **Adaptar** (sólo lectura: listado/búsqueda/detalle). Se elimina “+ New Product”. |
| 2 | Register New Product / Batch | **Excluir** (Web). |
| 3 | Raw Materials Inventory | **Adaptar** (sólo lectura). Se elimina “Add Material”. Alerta de stock bajo calculada con datos reales. |
| 4 | Register Raw Material Usage | **Excluir** (Web). |
| 5 | Sign In | **Conservar** sin “Don't have an account?” ni enlaces de registro. |
| 6 | Registro QA Manager | **Excluir**. |
| 7 | Registro Lab Operator | **Excluir**. |
| 8 | Command Center | **Adaptar** con datos reales. Se omiten latencia (ms), “Operational Distribution” porcentual y cifras fijas; “Overall health” sólo si hay KPI dashboard. |
| 9 | Navigation Menu | **Adaptar** como NavigationDrawer/“Más”. “Sincronizar telemetría” → refresco manual. “Soporte/Documentación” se omiten (sin destino real). |
| 10, 19 | Splash / vacío | Splash con verificación de sesión. |
| 11–14 | Production Batches + Batch Detail (General / Raw Materials Used) | **Conservar** sin “+ New Batch”. |
| 15 | Release Batch | **Conservar** (QA/ADMIN), campos exigidos por el endpoint: fecha y notas. |
| 16 | Reject Batch | **Conservar** (QA/ADMIN): fecha y motivo. |
| 17 | Telemetry Dashboard | **Conservar**: selector de equipo (en lugar de “área”), estado, anomalías, gráfico 15m/1h/6h/24h, lecturas actuales, eventos anómalos. Se omiten latencia, “Sampling rate” y “Acknowledge All”. |
| 18 | Raw Telemetry Data Log | **Conservar**: equipo, rango de fechas, lista, paginación local. |
| 20 | Compliance Alerts + Deviation Details (Unresolved) | **Conservar** con Acknowledge/Resolve. |
| 21 | Deviation Details (Resolved) | **Conservar** (sólo lectura). |
| 22 | Resumen de Facturación | **Adaptar**: sin “Cambiar Plan”, “Cancelar Suscripción” ni “Recibo PDF”. |
| 23–24 | Subscription Plans (mensual/anual) + Select Plan | **Excluir** (Web/Stripe). |

## 3. Funcionalidades que SÍ tendrá la app

1. Splash → verificación de token (expiración por claim `exp`) → Sign In o app.
2. Sign In (username/password, mostrar/ocultar, validación, errores backend), sesión segura (`flutter_secure_storage`), logout, expiración ante 401.
3. Verificación de onboarding: si `nextStep ≠ READY` o `laboratoryId` nulo → pantalla “Completa la configuración en QualiTrack Web”.
4. Command Center: usuario/rol, laboratorio, equipos (y con atención), lotes (pendientes/en progreso), alertas abiertas/críticas, materiales bajo mínimo, KPI real si existe, suscripción.
5. Equipos: lista con búsqueda y filtros por estado; detalle con datos, sensor vinculado, estado de telemetría, límites BPM, mantenimiento, tendencias, eventos de cumplimiento y audit log.
6. Telemetría: selección de equipo, estado (online/offline + OPERATIONAL/WARNING/CRITICAL/OFFLINE), últimas mediciones por parámetro con objetivo BPM, gráfico `fl_chart` con rangos construidos sobre timestamps reales, anomalías, refresco manual y polling cada 15 s (cancelado al salir).
7. Historial de telemetría (Raw Telemetry Data Log) con rango de fechas y estado de anomalía.
8. Alertas: contadores, filtros (All / Unresolved / Acknowledged / Resolved / Critical), detalle, Acknowledge y Resolve con notas (QA/ADMIN).
9. Lotes: contadores, filtros, detalle (General / Raw Materials Used / Alertas), Release/Reject con confirmación (QA/ADMIN), errores del backend visibles.
10. Inventario: materiales con stock físico/usable/mínimo y estado de stock; detalle con recepciones, movimientos y uso en lotes.
11. Productos: catálogo de sólo lectura con búsqueda y detalle.
12. Reportes/KPIs: KPI dashboard (o vacío), historial de reportes.
13. Facturación: plan actual, ciclo, estado, periodo, límites del plan, historial de pagos.
14. Perfil y Acerca de; English (por defecto) y Español.

## 4. Funcionalidades de los mockups que quedan FUERA

Register QA Manager / Lab Operator (sign-up), New Product y su formulario, Add Material y formulario de registro de materia prima, Register Raw Material Usage, New Batch, Subscription Plans / Select Plan, Checkout, Change Plan, Cancel Subscription, Recibo PDF, Acknowledge All de telemetría, latencia/ping, sampling rate, distribución operacional porcentual, Soporte/Documentación, cualquier POST de telemetría, recepción/consumo/importación de inventario, registro de equipos/mantenimiento/BPM, gestión de usuarios/staff, generación de reportes.

## 5. Arquitectura Flutter propuesta

DDD por Bounded Context, cuatro capas por módulo (detalle en `architecture.md`):

- **domain**: entidades, value objects, enums, interfaces de repositorio, reglas puras (p. ej. `Batch.canBeReviewed`, `RawMaterial.isBelowMinimum`). Sin Flutter/Dio.
- **application**: casos de uso (queries/commands) que dependen de interfaces de repositorio.
- **infrastructure**: DTOs (`fromJson` → `toDomain`), remote data sources sobre un único `ApiClient` (Dio), implementaciones de repositorio.
- **presentation**: BLoC (events/states), pages, widgets.
- **shared**: `Failure` tipado, `ApiClient`, `AuthInterceptor`, `ApiExceptionMapper`, `ApiConfig` (`--dart-define=API_BASE_URL`), `SecureSessionStorage`, widgets de estado (loading/empty/error/retry), badges accesibles.
- **app**: `QualiTrackApp`, `AppRouter` (go_router con `redirect` + `refreshListenable` de sesión), `injection.dart` (get_it), tema (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppTheme`, Material 3), localización.
- **command_center**: módulo de composición de UI (application + presentation) que consume casos de uso de otros BCs; no es un Bounded Context.

Paquetes: `flutter_bloc`, `dio`, `get_it`, `go_router`, `flutter_secure_storage`, `intl`, `equatable`, `fl_chart`, `flutter_localizations`; dev: `bloc_test`, `mocktail`, `flutter_lints`.

## 6. Árbol inicial de `lib/`

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── dependency_injection/injection.dart
│   ├── router/app_router.dart, app_routes.dart, main_shell.dart
│   ├── theme/app_colors.dart, app_typography.dart, app_spacing.dart, app_radius.dart, app_theme.dart
│   └── l10n/app_localizations.dart (+ en/es)
├── shared/
│   ├── domain/failure.dart, session/user_role.dart
│   ├── application/use_case.dart
│   ├── infrastructure/
│   │   ├── configuration/api_config.dart
│   │   ├── http/api_client.dart, auth_interceptor.dart, api_exception_mapper.dart, json_utils.dart
│   │   └── storage/secure_session_storage.dart
│   └── presentation/widgets/ (async_state_view, empty_state, error_state, status_badge, info_card, section_header, key_value_row, date_format)
├── iam/            domain · application · infrastructure · presentation (splash, sign_in, setup_required, profile)
├── laboratory/     laboratory + products (read-only)
├── equipment/      equipment, maintenance, bpm configs
├── tracking/       status, measurements, history, live polling
├── compliance/     deviation alerts, compliance events, review actions
├── batch/          batches, raw material usage, release/reject
├── inventory/      materials, receipts, movements, usages
├── reporting/      kpi dashboard, reports, trends, audit logs
├── subscription/   subscription, payments, plans (read-only)
└── command_center/ application · presentation
```

## 7. Plan de implementación por etapas

| Etapa | Contenido | Commit sugerido |
|---|---|---|
| 1 | Análisis y documentación (este archivo, `mobile-api-mapping.md`, `architecture.md`) | `docs: add mobile analysis and API mapping` |
| 2 | Proyecto Flutter, pubspec, lints, shared/core, theme, networking, secure storage, DI, routing | `chore: initialize QualiTrack Flutter application` |
| 3 | IAM: splash, sign-in, sesión JWT, onboarding, logout, 401 | `feat(iam): implement mobile authentication` |
| 4 | Equipment (lista, filtros, detalle, mantenimiento, BPM) | `feat(equipment): add equipment monitoring` |
| 5 | Tracking & Telemetry (dashboard, polling, gráfico, historial) | `feat(tracking): add live telemetry monitoring` |
| 6 | Compliance & Alerts (lista agregada, filtros, detalle, acknowledge/resolve) | `feat(alerts): add compliance alert review` |
| 7 | Product Batches (lista, detalle, materias primas, release/reject) | `feat(batch): add batch review workflow` |
| 8 | Inventory (+ Products de Laboratory) | `feat(inventory): add inventory monitoring` |
| 9 | Reporting/Audit | `feat(reporting): add KPI dashboard` |
| 10 | Billing | `feat(subscription): add billing summary` |
| 11 | Command Center | `feat(dashboard): add command center` |
| 12 | i18n + accesibilidad + pulido responsive | `feat(i18n): add English and Spanish localization` |
| 13 | Tests (domain, application, infrastructure, BLoC, widgets) | `test: add mobile application tests` |
| 14 | README y documentación final | `docs: document QualiTrack mobile architecture` |

Tras cada etapa: `dart format .`, `flutter analyze`, `flutter test`.
