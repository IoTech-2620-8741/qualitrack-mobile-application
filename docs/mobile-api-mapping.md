# QualiTrack Mobile — API Mapping

Fuente de verdad: `qualitrack-platform` v0.13.2 (rama `develop`).
Todas las rutas son relativas a `API_BASE_URL` (p. ej. `http://10.0.2.2:8080`) y comienzan con `/api/v1`.
`{lab}` = laboratorio de la sesión, `{env}` = ambiente.

## Reglas transversales del backend

| Tema | Comportamiento |
|---|---|
| Autenticación | `POST /authentication/sign-in` es público. Todo lo demás exige `Authorization: Bearer <JWT>`. Sin token → `401`. |
| Sesión | `AuthenticatedUserResource {id, username, token, roles, laboratoryId, passwordChangeRequired}`. El JWT expira a los 7 días y también se valida contra el claim `userId`, porque el usuario puede cambiar su nombre de usuario. |
| Onboarding | `GET /users/me/onboarding` → `nextStep ∈ {PASSWORD_CHANGE, SUBSCRIPTION, LABORATORY, READY}`. Mientras no sea `READY`, las rutas operativas responden `403 {code: ONBOARDING_REQUIRED, nextStep}`. |
| Roles | `ROLE_ADMIN`, `ROLE_QA_MANAGER`, `ROLE_LAB_OPERATOR`, `ROLE_AUDITOR`. El auditor solo lee: toda escritura le responde `403`. |
| Laboratorio | Las rutas `/laboratories/{lab}/**` responden `403` si el laboratorio no es el del usuario. |
| Errores | `ErrorResource {code, message, details}`: `400`, `403`, `404`, `409`, `413`/`415` (foto), `502` (proveedor de correo). |
| Paginación | No existe. Los avisos aceptan `limit` (máximo 100). |
| Fechas | Los periodos (`from`/`to`) se envían como `Date.toISOString()` en UTC, igual que Web. La telemetría acepta hasta 31 días. |

## Tabla de mapeo

“Cualquiera” = cualquier rol con cuenta en el laboratorio. Las acciones de escritura de la app son solo las de la tabla; todo lo demás se registra en QualiTrack Web.

| Módulo | Pantalla | Bounded Context | Endpoint | Método | Rol |
|---|---|---|---|---|---|
| iam | Inicio de sesión | IAM | `/authentication/sign-in` | POST | Público |
| iam | Splash / guardia de sesión | IAM | `/users/me/onboarding` | GET | Cualquiera |
| iam | Cambio de contraseña (obligatorio con la temporal y desde el perfil) | IAM | `/users/me/password-changes` | POST | Cualquiera |
| laboratory | Panel, perfil | Laboratory | `/laboratories/{lab}` | GET | Cualquiera |
| laboratory | Nombres de ambientes en todas las listas | Laboratory | `/laboratories/{lab}/environments` | GET | Cualquiera |
| laboratory | Catálogo de productos (por ambiente) | Laboratory | `/laboratories/{lab}/environments/{env}/products` | GET | Cualquiera |
| laboratory | Nombres del personal (quién atendió, firmó o registró) | Laboratory | `/laboratories/{lab}/staff` | GET | Cualquiera |
| equipment | Equipos | Equipment | `/laboratories/{lab}/equipments` | GET | Cualquiera |
| equipment | Detalle de equipo | Equipment | `/laboratories/{lab}/equipments/{id}` | GET | Cualquiera |
| equipment | Detalle → mantenimientos | Equipment | `/laboratories/{lab}/environments/{env}/equipments/{id}/maintenance-records` | GET | Cualquiera |
| equipment | Detalle → parámetros BPM | Equipment | `/laboratories/{lab}/equipments/{id}/bpm-configs` | GET | Cualquiera |
| tracking | Monitoreo, equipos, panel | Tracking | `/laboratories/{lab}/environments/{env}/devices/{id}/telemetry-status` | GET | Cualquiera |
| tracking | Monitoreo e historial (dispositivo ambiental) | Tracking | `/laboratories/{lab}/environments/{env}/telemetry-measurements?from&to` | GET | Cualquiera |
| tracking | Monitoreo e historial (monitor de contenedor) | Tracking | `/laboratories/{lab}/environments/{env}/container-monitors/{id}/telemetry-measurements?from&to` | GET | Cualquiera |
| tracking | Monitoreo → rangos normal y crítico vigentes | Tracking | `/laboratories/{lab}/environments/{env}/devices/{id}/environmental-profile` | GET | Cualquiera |
| tracking | Monitoreo → acciones automáticas del contenedor | Tracking | `/laboratories/{lab}/environments/{env}/container-monitors/{id}/actuation-events?from&to` | GET | Cualquiera |
| compliance | Alertas (todas las de cada ambiente) | Compliance & Alerting | `/laboratories/{lab}/environments/{env}/deviation-alerts` | GET | Cualquiera |
| compliance | Detalle de alerta | Compliance & Alerting | `/deviation-alerts/{id}` | GET | Cualquiera |
| compliance | Detalle → atender | Compliance & Alerting | `/deviation-alerts/{id}/acknowledgements` | POST | Operario, QA |
| compliance | Detalle → resolver con notas | Compliance & Alerting | `/deviation-alerts/{id}/resolutions` | POST | Operario, QA |
| compliance | Detalle de equipo → eventos de cumplimiento | Compliance & Alerting | `/laboratories/{lab}/equipments/{id}/compliance-events` | GET | Cualquiera |
| compliance | Detalle de lote → eventos de cumplimiento | Compliance & Alerting | `/batches/{id}/compliance-events` | GET | Cualquiera |
| compliance | Campanita (contador) | Compliance & Alerting | `/users/me/notifications/unread-count` | GET | Cualquiera |
| compliance | Avisos | Compliance & Alerting | `/users/me/notifications?limit` | GET | Cualquiera |
| compliance | Avisos → marcar uno o todos como leídos | Compliance & Alerting | `/users/me/notifications/{id}/read-receipts`, `/users/me/notifications/read-receipts` | POST | Cualquiera |
| compliance | Preferencias de notificación | Compliance & Alerting | `/users/me/notification-preferences` | GET, PUT | Cualquiera |
| batch | Lotes del laboratorio | Product Batch | `/laboratories/{lab}/batches` | GET | Cualquiera |
| batch | Detalle → trazabilidad (materias primas, equipos, personal, contenedor, firma) | Product Batch | `/laboratories/{lab}/environments/{env}/products/{p}/batches/{id}/traceability` | GET | Cualquiera |
| batch | Detalle → liberar (firma digital) | Product Batch | `/laboratories/{lab}/environments/{env}/products/{p}/batches/{id}/releases` | POST | QA |
| batch | Detalle → rechazar con motivo | Product Batch | `/laboratories/{lab}/environments/{env}/products/{p}/batches/{id}/rejections` | POST | QA |
| inventory | Materias primas (de cada ambiente) | Inventory | `/laboratories/{lab}/environments/{env}/raw-materials` | GET | Cualquiera |
| inventory | Detalle de materia prima | Inventory | `/laboratories/{lab}/environments/{env}/raw-materials/{id}` | GET | Cualquiera |
| inventory | Detalle → lotes recibidos | Inventory | `/laboratories/{lab}/environments/{env}/raw-materials/{id}/batches` | GET | Cualquiera |
| inventory | Detalle → movimientos | Inventory | `/laboratories/{lab}/environments/{env}/raw-materials/{id}/movements` | GET | Cualquiera |
| inventory | Detalle → lotes de producto que la usaron | Inventory | `/laboratories/{lab}/environments/{env}/raw-materials/{id}/usages` | GET | Cualquiera |
| reporting | Reportes → resumen de mediciones del periodo | Reporting & Audit | `/laboratories/{lab}/kpi-dashboards?from&to` | GET | Cualquiera |
| reporting | Reportes y equipo → indicadores de desviaciones | Reporting & Audit | `/laboratories/{lab}/environments/{env}/deviation-trends?from&to` | GET | Cualquiera |
| reporting | Historial de reportes | Reporting & Audit | `/laboratories/{lab}/reports` | GET | Cualquiera |
| reporting | Detalle de equipo → auditoría | Reporting & Audit | `/laboratories/{lab}/equipments/{id}/audit-logs` | GET | Cualquiera |
| reporting | Detalle de lote → auditoría | Reporting & Audit | `/batches/{id}/audit-logs` | GET | Cualquiera |
| subscription | Suscripción | Payments & Subscriptions | `/laboratories/{lab}/subscriptions` | GET | QA |
| subscription | Suscripción → pagos | Payments & Subscriptions | `/subscriptions/{id}/payments` | GET | QA |
| subscription | Suscripción → límites del plan | Payments & Subscriptions | `/subscription-plans` | GET | QA |
| profile | Perfil, cabecera del menú | Profile | `/users/me/profile` | GET, PUT | Cualquiera |
| profile | Foto de perfil (imagen JPG, PNG o WebP de hasta 2 MB en el cuerpo) | Profile | `/users/me/profile/photo` | GET, PUT, DELETE | Cualquiera |
| command_center | Panel | (composición de UI) | laboratorio, ambientes, equipos, conexión, lotes, alertas, materias primas y, para QA, suscripción | GET | Cualquiera |

## Endpoints que la app no usa

| Endpoint | Motivo |
|---|---|
| `POST /authentication/sign-up`, `password-recovery-requests`, `password-resets` | El registro y la recuperación de contraseña se hacen en Web. |
| `PUT /users/me` (usuario y correo) | Los datos de acceso se cambian en Web. |
| Altas y cambios de laboratorio, ambientes, usos, personal, productos, equipos, dispositivos IoT, perfiles ambientales, parámetros BPM, materias primas, lotes de materia prima y su revisión o almacenamiento | Configuración y registro en Web. |
| `POST .../products/{p}/batches` y sus consumos, equipos, personal y contenedor | La fabricación se registra en Web. |
| `POST .../telemetry-measurements`, `.../actuation-events`, `.../deviation-alerts` | Los publica el Edge; la app nunca publica telemetría. |
| `POST /deviation-alerts/{id}/email-notifications` | El reenvío del correo queda en Web. |
| `GET /laboratories/{lab}/staff/{id}/profile`, `.../audit-logs`, `POST .../deactivations` | Gestión del personal en Web. |
| `POST` de reportes y `GET /reports/{id}/content` | Los reportes se generan y descargan en Web. |
| `POST /subscription-checkout-sessions`, `/subscriptions/{id}/cancellation-requests`, `/stripe/webhooks` | Pagos y cancelación en Web. |
| Push (`TS77`, Firebase) | Pendiente: requiere el proyecto de Firebase y el registro del dispositivo en el backend. |
