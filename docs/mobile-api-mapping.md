# QualiTrack Mobile — API Mapping

Fuente de verdad: `qualitrack-platform` (rama `develop`, commit `923048a`).
Todas las rutas son relativas a `API_BASE_URL` (p. ej. `http://10.0.2.2:8080`) y comienzan con `/api/v1`.

## Reglas transversales verificadas en el backend

| Tema | Comportamiento real |
|---|---|
| Autenticación | `POST /api/v1/authentication/sign-in` es público. Todo lo demás exige `Authorization: Bearer <JWT>`. Sin token → `401` (cuerpo HTML/“Unauthorized”). |
| JWT | Claims: `sub`, `userId`, `laboratoryId`, `roles`, `exp`. Expira a los **7 días** (`authorization.jwt.expiration.days=7`). |
| Tenant | `TenantResourceInterceptor` valida cada path/query param reconocido (`laboratoryId`, `labId`, `userId`, `equipmentId`, `batchId`, `alertId`, `rawMaterialId`, `productId`, `staffId`, `reportId`, `subscriptionId`) contra el laboratorio del token → `403 {code: ACCESS_DENIED}`. |
| Onboarding | `OnboardingInterceptor`: si `GET /users/me/onboarding` no devuelve `nextStep = READY`, los endpoints operativos responden `403 {code: ONBOARDING_REQUIRED, nextStep}`. `nextStep ∈ {SUBSCRIPTION, LABORATORY, READY}`. |
| Roles | `ROLE_ADMIN`, `ROLE_QA_MANAGER`, `ROLE_LAB_OPERATOR` (`iam.domain.model.valueobjects.Roles`). |
| Errores | `ErrorResource {code, message, details}`. `VALIDATION_ERROR`→400, `*_NOT_FOUND`→404, `*_CONFLICT`→409, `UNEXPECTED_ERROR`→500, `ACCESS_DENIED`→403, Inventory `INVENTORY_CONFLICT`→409. Algunos GET devuelven 404 sin cuerpo. |
| Paginación | No existe en ningún endpoint. Todas las listas son completas. |
| Fechas | Telemetría, alertas y eventos guardan `timestamp` como **String** (ISO-8601 esperado). Filtro `from`/`to` de historial compara strings; Web envía `Date.toISOString()` (UTC). |

## Enums reales

| Enum | Valores |
|---|---|
| AlertStatus | `UNRESOLVED`, `ACKNOWLEDGED`, `RESOLVED` |
| AlertSeverity | `LOW`, `WARNING`, `CRITICAL` |
| BatchStatus | `PENDING`, `IN_PROGRESS`, `RELEASED`, `REJECTED` |
| TelemetryStatus | `OPERATIONAL`, `WARNING`, `CRITICAL`, `OFFLINE` |
| EquipmentStatus | `OPERATIONAL`, `MAINTENANCE`, `OUT_OF_SERVICE`, `INACTIVE` (se expone como String) |
| MaintenanceType | `PREVENTIVE`, `CORRECTIVE`, `CALIBRATION`, `INSPECTION`, `OTHER` |
| RawMaterialBatchStatus (recepción) | `QUARANTINED`, `RELEASED`, `OBSERVED`, `REJECTED` |
| SubscriptionStatus | `ACTIVE`, `INACTIVE`, `PENDING_PAYMENT`, `CANCELLED`, `EXPIRED` |
| PaymentStatus | `PENDING`, `PAID`, `FAILED`, `CANCELLED`, `REFUNDED` |
| BillingCycle | `MONTHLY`, `YEARLY` |
| PlanCode | `FREE`, `BASIC`, `PROFESSIONAL`, `ENTERPRISE` |
| KpiMetricStatus | `ON_TRACK`, `AT_RISK`, `CRITICAL`, `UNKNOWN` |
| AuditAction | `CREATE`, `UPDATE`, `DELETE`, `RELEASE`, `REJECT`, `APPROVE`, `REGISTER`, `REMOVE`, `EXPORT`, `GENERATE`, `LOGIN`, `LOGOUT`, `SYSTEM` |
| ReportType | `BATCH_TRACEABILITY`, `COMPLIANCE_PERIOD`, `EQUIPMENT_LOG`, `KPI_SUMMARY` |
| TrendDirection | `INCREASING`, `DECREASING`, `STABLE` |
| ComplianceEventType | `DEVIATION_ALERT_CREATED`, `DEVIATION_ALERT_ACKNOWLEDGED`, `DEVIATION_ALERT_RESOLVED`, `NOTIFICATION_PREFERENCE_UPDATED`, `BATCH_BLOCKED`, `BATCH_RELEASED`, `BATCH_REJECTED`, `RAW_MATERIAL_LOW_STOCK`, `EQUIPMENT_CALIBRATION_EXPIRED`, `EQUIPMENT_DEVIATION_DETECTED` |

## Tabla de mapeo

“Any” = cualquier rol autenticado cuyo laboratorio coincida (el backend sólo aplica aislamiento por tenant).
“QA/ADMIN (UI)” = la app sólo muestra la acción a `ROLE_QA_MANAGER` / `ROLE_ADMIN`; ver *Brechas*.

| Mobile module | Screen | Bounded Context | Backend endpoint | HTTP method | Read/Action | Role |
|---|---|---|---|---|---|---|
| iam | Sign In | Identity & Access Management | `/api/v1/authentication/sign-in` | POST | Action (login) | Public |
| iam | Splash / Session gate | Identity & Access Management | `/api/v1/users/me/onboarding` | GET | Read | Any |
| iam | Profile | Identity & Access Management | `/api/v1/users/{userId}` | GET | Read | Any (propio usuario) |
| laboratory | Command Center / Profile / Drawer header | Laboratory Management | `/api/v1/laboratories/{laboratoryId}` | GET | Read | Any |
| laboratory | Products (catálogo) | Laboratory Management | `/api/v1/laboratories/{laboratoryId}/products` | GET | Read | Any |
| equipment | Equipment list | Equipment Management | `/api/v1/equipments?labId={laboratoryId}` | GET | Read | Any |
| equipment | Equipment detail | Equipment Management | `/api/v1/equipments/{equipmentId}` | GET | Read | Any |
| equipment | Equipment detail → Maintenance | Equipment Management | `/api/v1/equipments/{equipmentId}/maintenance-records` | GET | Read | Any |
| equipment / tracking | Equipment detail → BPM limits, Telemetry targets | Equipment Management | `/api/v1/equipments/{equipmentId}/bpm-configs` | GET | Read | Any |
| tracking | Telemetry Dashboard | Tracking & Telemetry | `/api/v1/equipments/{equipmentId}/telemetry-status` | GET | Read (polling 15 s) | Any |
| tracking | Telemetry Dashboard | Tracking & Telemetry | `/api/v1/equipments/{equipmentId}/telemetry-measurements` | GET | Read (polling 15 s) | Any |
| tracking | Telemetry Dashboard (chart, anomalies) / Raw Telemetry Data Log | Tracking & Telemetry | `/api/v1/equipments/{equipmentId}/telemetry-history?from&to` | GET | Read | Any |
| compliance | Compliance Alerts (lista del laboratorio = agregación por equipo, igual que Web) | Compliance & Alerting | `/api/v1/equipments/{equipmentId}/deviation-alerts?status&severity` | GET | Read | Any |
| compliance / batch | Batch detail → Alerts | Compliance & Alerting | `/api/v1/batches/{batchId}/deviation-alerts` | GET | Read | Any |
| compliance | Deviation Details | Compliance & Alerting | `/api/v1/deviation-alerts/{alertId}` | GET | Read | Any |
| compliance | Deviation Details → Acknowledge | Compliance & Alerting | `/api/v1/deviation-alerts/{alertId}` body `{status: ACKNOWLEDGED, performedBy}` | PATCH | Action (review) | QA/ADMIN (UI) |
| compliance | Deviation Details → Resolve | Compliance & Alerting | `/api/v1/deviation-alerts/{alertId}` body `{status: RESOLVED, performedBy, resolutionNotes}` | PATCH | Action (review) | QA/ADMIN (UI) |
| compliance | Equipment detail → Compliance timeline | Compliance & Alerting | `/api/v1/equipments/{equipmentId}/compliance-events` | GET | Read | Any |
| compliance | Batch detail → Compliance timeline | Compliance & Alerting | `/api/v1/batches/{batchId}/compliance-events` | GET | Read | Any |
| batch | Production Batches | Product Batch Management | `/api/v1/batches?labId={laboratoryId}` | GET | Read | Any |
| batch | Batch Detail → General Information | Product Batch Management | `/api/v1/batches/{batchId}` | GET | Read | Any |
| batch | Batch Detail → Raw Materials Used | Product Batch Management | `/api/v1/batches/{batchId}/raw-materials` | GET | Read | Any |
| batch | Release Batch | Product Batch Management | `/api/v1/batches/{batchId}` body `{status: RELEASED, releaseDate, notes}` | PATCH | Action (review) | QA/ADMIN (UI) |
| batch | Reject Batch | Product Batch Management | `/api/v1/batches/{batchId}` body `{status: REJECTED, rejectionDate, reason}` | PATCH | Action (review) | QA/ADMIN (UI) |
| inventory | Raw Materials Inventory | Inventory Management | `/api/v1/laboratories/{laboratoryId}/inventory/materials` | GET | Read | Any |
| inventory | Material detail → Receipts | Inventory Management | `/api/v1/laboratories/{laboratoryId}/inventory/materials/{materialId}/receipts` | GET | Read | Any |
| inventory | Material detail → Movements | Inventory Management | `/api/v1/laboratories/{laboratoryId}/inventory/materials/{materialId}/movements` | GET | Read | Any |
| reporting | KPI Dashboard | Reporting & Audit | `/api/v1/laboratories/{laboratoryId}/kpi-dashboards` | GET | Read (404 ⇒ empty state) | Any |
| reporting | Report history | Reporting & Audit | `/api/v1/laboratories/{laboratoryId}/reports` | GET | Read | Any |
| reporting | Equipment detail → Deviation trends | Reporting & Audit | `/api/v1/equipments/{equipmentId}/deviation-trends` | GET | Read | Any |
| reporting | Equipment detail → Audit log | Reporting & Audit | `/api/v1/equipments/{equipmentId}/audit-logs?dateFrom&dateTo` | GET | Read | Any |
| reporting | Batch detail → Audit log | Reporting & Audit | `/api/v1/batches/{batchId}/audit-logs?dateFrom&dateTo` | GET | Read | Any |
| subscription | Billing Summary → Current plan | Payments & Subscriptions | `/api/v1/laboratories/{laboratoryId}/subscriptions?status=ACTIVE` | GET | Read (404 ⇒ sin suscripción activa) | Any |
| subscription | Billing Summary → Subscription history | Payments & Subscriptions | `/api/v1/laboratories/{laboratoryId}/billing-summary` | GET | Read | Any |
| subscription | Billing Summary → Payments | Payments & Subscriptions | `/api/v1/subscriptions/{subscriptionId}/payments` | GET | Read | Any |
| subscription | Billing Summary → Plan limits | Payments & Subscriptions | `/api/v1/subscription-plans` | GET | Read (sólo para mostrar `maxUsers`/`maxEquipment` del plan actual) | Any |
| command_center | Command Center | (composición de UI) | laboratory, equipment, telemetry-status, batches, deviation-alerts, inventory/materials, kpi-dashboards, subscriptions?status=ACTIVE | GET | Read | Any |

## Endpoints existentes que mobile NO usará (y por qué)

| Endpoint | Motivo |
|---|---|
| `POST /authentication/sign-up` | Registro permanece en Web. |
| `POST /laboratories`, `PUT /laboratories/{id}` | Configuración del laboratorio en Web. |
| `POST /laboratories/{id}/products`, `/staff`, `/raw-materials`; `PATCH /staff/{id}`; `GET /laboratories/{id}/staff` | Administración (CRUD) en Web. `GET …/raw-materials` es el catálogo legado del BC Laboratory; Web usa Inventory. |
| `POST /laboratories/{id}/inventory/materials`, `PUT …/materials/{id}`, `POST …/receipts`, `POST /receipts/{id}/reviews`, `POST …/consumptions`, `GET/POST …/legacy-materials` | Registro/recepción/consumo/importación en Web. `usable-receipts` sólo sirve para consumir. |
| `POST /equipments`, `POST …/maintenance-records`, `POST …/bpm-configs` | Configuración en Web. |
| `POST …/telemetry-measurements`, `POST …/telemetry-history`, `PUT …/telemetry-status` | Adquisición IoT (Edge/ESP32). El móvil nunca publica telemetría. |
| `POST /equipments/{id}/deviation-alerts` | Las alertas las genera el sistema. |
| `POST /batches`, `POST /batches/{id}/raw-materials`, `GET /batches?status=` | Creación en Web. El filtro por estado se hace sobre la lista del laboratorio ya cargada (evita peticiones duplicadas). |
| `GET/PUT /users/{id}/notification-preferences` | No hay push real todavía; se deja fuera en esta etapa. |
| `GET /users`, `PUT /users/{id}/roles/{role}`, `PATCH /users/{id}`, `GET /roles` | Administración de usuarios en Web. |
| `POST /laboratories/{id}/kpi-dashboards`, `POST …/compliance-reports`, `POST /batches/{id}/reports`, `POST /equipments/{id}/log-reports`, `POST …/audit-logs` | Generan/escriben datos; no se generan reportes automáticamente desde mobile. |
| `GET /reports/{id}`, `GET /reports/{id}/content` | Descarga de PDF/CSV fuera de alcance en esta etapa (el listado de historial sí se muestra). |
| `POST /subscription-checkout-sessions`, `PATCH /subscriptions/{id}`, `POST /stripe/webhooks` | Checkout/cancelación/Stripe permanecen en Web. |
| `GET /raw-materials/{id}/compliance-events` | Opcional; no aparece en mockups. |
| `GET /raw-materials/{id}/usages` | Su control de tenant resuelve `rawMaterialId` contra el catálogo **legado** de Laboratory, mientras que los usos generados por Inventory guardan el id del material de Inventory. Mobile usa en su lugar los movimientos de Inventory (`productBatchId`) y `GET /batches/{id}/raw-materials`. |

## Brechas detectadas (no se modifica el backend)

1. **Autorización por rol de release/reject y acknowledge/resolve**: el backend sólo valida tenant (y que `performedBy` sea el usuario autenticado en alertas); **no** restringe por rol. Web tampoco oculta las acciones. Mobile las muestra sólo a `ROLE_QA_MANAGER`/`ROLE_ADMIN` como se pidió, pero esto **no** sustituye autorización del servidor. Se recomienda añadir `hasAnyAuthority('ROLE_QA_MANAGER','ROLE_ADMIN')` en `BatchController.updateBatchStatus` y `DeviationAlertController.updateAlertStatus` (mismo patrón que `InventoryController.review`). No se añadió porque no es un endpoint de consulta faltante.
2. **Alertas por laboratorio**: no existe `GET /laboratories/{id}/deviation-alerts`; se agrega por equipo (mismo enfoque que `DashboardStore` de Web, concurrencia limitada). No se crea endpoint nuevo para no duplicar.
3. **Sin estado online por laboratorio**: el estado de telemetría se consulta por equipo.
4. **Métricas del mockup sin fuente** (latencia en ms, “Sampling rate”, “Overall health 92.5%” fijo, distribución porcentual): se omiten; `overallHealthScore` sólo se muestra si existe un KPI dashboard real.
5. **IDs de materia prima**: `RawMaterialUsage.rawMaterialId` puede referirse al material de Inventory (consumos) o al catálogo legado (vínculos antiguos); por eso la trazabilidad por material se muestra con movimientos de Inventory.
6. **Recibo PDF de pagos**: no hay endpoint → no se muestra.
