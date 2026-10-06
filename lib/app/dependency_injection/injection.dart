import 'package:get_it/get_it.dart';

import '../../batch/application/batch_use_cases.dart';
import '../../batch/domain/batch.dart';
import '../../batch/infrastructure/batch_infrastructure.dart';
import '../../batch/presentation/bloc/batch_detail_bloc.dart';
import '../../batch/presentation/bloc/batches_bloc.dart';
import '../../command_center/application/get_command_center_summary.dart';
import '../../command_center/presentation/bloc/command_center_bloc.dart';
import '../../compliance/application/compliance_queries.dart';
import '../../compliance/domain/compliance.dart';
import '../../compliance/infrastructure/compliance_infrastructure.dart';
import '../../compliance/presentation/bloc/alert_detail_bloc.dart';
import '../../compliance/presentation/bloc/alerts_bloc.dart';
import '../../compliance/presentation/bloc/notification_preferences_bloc.dart';
import '../../compliance/presentation/bloc/notifications_bloc.dart';
import '../../compliance/presentation/bloc/unread_notifications_controller.dart';
import '../../equipment/application/equipment_queries.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/infrastructure/equipment_infrastructure.dart';
import '../../equipment/presentation/bloc/equipment_detail_bloc.dart';
import '../../equipment/presentation/bloc/equipment_list_bloc.dart';
import '../../iam/application/iam_use_cases.dart';
import '../../iam/application/session_controller.dart';
import '../../iam/domain/iam_repositories.dart';
import '../../iam/domain/user_session.dart';
import '../../iam/infrastructure/iam_remote_data_source.dart';
import '../../iam/infrastructure/iam_repositories_impl.dart';
import '../../iam/presentation/bloc/change_password_bloc.dart';
import '../../iam/presentation/bloc/sign_in_bloc.dart';
import '../../inventory/application/inventory_queries.dart';
import '../../inventory/domain/inventory.dart';
import '../../inventory/infrastructure/inventory_infrastructure.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../inventory/presentation/bloc/material_detail_bloc.dart';
import '../../laboratory/application/laboratory_queries.dart';
import '../../laboratory/domain/laboratory.dart';
import '../../laboratory/infrastructure/laboratory_infrastructure.dart';
import '../../laboratory/presentation/bloc/products_bloc.dart';
import '../../profile/application/profile_use_cases.dart';
import '../../profile/domain/profile.dart';
import '../../profile/infrastructure/profile_infrastructure.dart';
import '../../profile/presentation/bloc/current_profile_controller.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../reporting/application/reporting_queries.dart';
import '../../reporting/domain/reporting.dart';
import '../../reporting/infrastructure/reporting_infrastructure.dart';
import '../../reporting/presentation/bloc/reports_bloc.dart';
import '../../shared/domain/failure.dart';
import '../../shared/domain/value_objects.dart';
import '../../shared/infrastructure/configuration/api_config.dart';
import '../../shared/infrastructure/http/api_client.dart';
import '../../shared/infrastructure/http/auth_interceptor.dart';
import '../../shared/infrastructure/storage/secure_key_value_store.dart';
import '../../subscription/application/billing_queries.dart';
import '../../subscription/domain/subscription.dart';
import '../../subscription/infrastructure/subscription_infrastructure.dart';
import '../../subscription/presentation/bloc/billing_bloc.dart';
import '../../tracking/application/telemetry_queries.dart';
import '../../tracking/domain/telemetry.dart';
import '../../tracking/infrastructure/telemetry_infrastructure.dart';
import '../../tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import '../../tracking/presentation/bloc/telemetry_history_bloc.dart';

final GetIt sl = GetIt.instance;

/// Composition root. Widgets never call [sl] directly: the router builds
/// BLoCs through the factories registered here.
Future<void> configureDependencies({ApiConfig? config, SecureKeyValueStore? secureStore}) async {
  await sl.reset();

  // Configuration & shared infrastructure
  sl.registerSingleton<ApiConfig>(config ?? ApiConfig.fromEnvironment());
  sl.registerLazySingleton<SecureKeyValueStore>(() => secureStore ?? FlutterSecureKeyValueStore());
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      tokenProvider: () => sl<SessionController>().token,
      onUnauthorized: () => sl<SessionController>().expire(),
    ),
  );
  sl.registerLazySingleton<ApiClient>(() => ApiClient.create(config: sl(), authInterceptor: sl()));

  // Identity & Access Management
  sl.registerLazySingleton(() => IamRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<SessionRepository>(() => SecureSessionRepository(sl()));
  sl.registerLazySingleton(() => SignIn(sl(), sl()));
  sl.registerLazySingleton(() => RestoreSession(sl()));
  sl.registerLazySingleton(() => RememberSession(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => CheckOnboarding(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(
    () => SessionController(restoreSession: sl(), rememberSession: sl(), signOut: sl(), checkOnboarding: sl()),
  );

  // Laboratory Management
  sl.registerLazySingleton(() => LaboratoryRemoteDataSource(sl()));
  sl.registerLazySingleton<LaboratoryRepository>(() => LaboratoryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLaboratory(sl()));
  sl.registerLazySingleton(() => GetEnvironments(sl()));
  sl.registerLazySingleton(() => GetProductCatalog(sl()));
  sl.registerLazySingleton(() => GetUserDirectory(sl()));

  // Equipment Management
  sl.registerLazySingleton(() => EquipmentRemoteDataSource(sl()));
  sl.registerLazySingleton<EquipmentRepository>(() => EquipmentRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetEquipments(sl()));
  sl.registerLazySingleton(() => GetEquipment(sl()));
  sl.registerLazySingleton(() => GetMaintenanceHistory(sl()));
  sl.registerLazySingleton(() => GetBpmConfigs(sl()));

  // Tracking & Telemetry
  sl.registerLazySingleton(() => TelemetryRemoteDataSource(sl()));
  sl.registerLazySingleton<TelemetryRepository>(() => TelemetryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDeviceConnection(sl()));
  sl.registerLazySingleton(() => GetDeviceConnections(sl()));
  sl.registerLazySingleton(() => GetMeasurements(sl()));
  sl.registerLazySingleton(() => GetEnvironmentalProfile(sl()));
  sl.registerLazySingleton(() => GetActuationEvents(sl()));

  // Compliance & Alerting (alerts and in-app notifications)
  sl.registerLazySingleton(() => ComplianceRemoteDataSource(sl()));
  sl.registerLazySingleton<ComplianceRepository>(() => ComplianceRepositoryImpl(sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLaboratoryAlerts(sl()));
  sl.registerLazySingleton(() => GetAlertDetail(sl()));
  sl.registerLazySingleton(() => AcknowledgeAlert(sl()));
  sl.registerLazySingleton(() => ResolveAlert(sl()));
  sl.registerLazySingleton(() => GetEquipmentComplianceEvents(sl()));
  sl.registerLazySingleton(() => GetBatchComplianceEvents(sl()));
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => GetUnreadNotificationCount(sl()));
  sl.registerLazySingleton(() => MarkNotificationRead(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsRead(sl()));
  sl.registerLazySingleton(() => GetNotificationPreferences(sl()));
  sl.registerLazySingleton(() => UpdateNotificationPreferences(sl()));
  sl.registerLazySingleton(() => UnreadNotificationsController(getUnreadCount: sl()));

  // Product Batch Management
  sl.registerLazySingleton(() => BatchRemoteDataSource(sl()));
  sl.registerLazySingleton<BatchRepository>(() => BatchRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBatches(sl()));
  sl.registerLazySingleton(() => GetBatchTraceability(sl()));
  sl.registerLazySingleton(() => ReleaseBatch(sl()));
  sl.registerLazySingleton(() => RejectBatch(sl()));

  // Inventory Management
  sl.registerLazySingleton(() => InventoryRemoteDataSource(sl()));
  sl.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetInventoryMaterials(sl()));
  sl.registerLazySingleton(() => GetInventoryMaterial(sl()));
  sl.registerLazySingleton(() => GetMaterialReceipts(sl()));
  sl.registerLazySingleton(() => GetInventoryMovements(sl()));
  sl.registerLazySingleton(() => GetMaterialUsages(sl()));

  // Reporting & Audit
  sl.registerLazySingleton(() => ReportingRemoteDataSource(sl()));
  sl.registerLazySingleton<ReportingRepository>(() => ReportingRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetKpiDashboard(sl()));
  sl.registerLazySingleton(() => GetDeviationTrends(sl()));
  sl.registerLazySingleton(() => GetReportHistory(sl()));
  sl.registerLazySingleton(() => GetEquipmentAuditLogs(sl()));
  sl.registerLazySingleton(() => GetBatchAuditLogs(sl()));

  // Payments & Subscriptions
  sl.registerLazySingleton(() => SubscriptionRemoteDataSource(sl()));
  sl.registerLazySingleton<SubscriptionRepository>(() => SubscriptionRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBillingSummary(sl()));

  // Profile
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMyProfile(sl()));
  sl.registerLazySingleton(() => UpdateMyProfile(sl()));
  sl.registerLazySingleton(() => GetMyPhoto(sl()));
  sl.registerLazySingleton(() => UploadMyPhoto(sl()));
  sl.registerLazySingleton(() => RemoveMyPhoto(sl()));
  sl.registerLazySingleton(() => CurrentProfileController(getProfile: sl(), getPhoto: sl()));

  // Command Center (UI composition)
  sl.registerLazySingleton(
    () => GetCommandCenterSummary(
      getLaboratory: sl(),
      getEnvironments: sl(),
      getEquipments: sl(),
      getConnections: sl(),
      getBatches: sl(),
      getAlerts: sl(),
      getMaterials: sl(),
      getBilling: sl(),
    ),
  );

  _registerBlocs();
}

LaboratoryId _laboratoryId() => sl<SessionController>().requireLaboratoryId();

UserSession _session() {
  final session = sl<SessionController>().session;
  if (session == null) throw const UnauthorizedFailure(code: 'NO_SESSION');
  return session;
}

void _registerBlocs() {
  sl.registerFactory(() => SignInBloc(signIn: sl(), session: sl()));
  sl.registerFactory(() => ChangePasswordBloc(changePassword: sl()));
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      updateProfile: sl(),
      getPhoto: sl(),
      uploadPhoto: sl(),
      removePhoto: sl(),
      getLaboratory: sl(),
      laboratoryId: () => sl<SessionController>().session?.laboratoryId,
      onProfileChanged: (profile) => sl<CurrentProfileController>().changed(profile),
    ),
  );
  sl.registerFactory(
    () => CommandCenterBloc(
      getSummary: sl(),
      laboratoryId: _laboratoryId,
      includeSubscription: _session().canManageQuality,
    ),
  );
  sl.registerFactory(() => ProductsBloc(getCatalog: sl(), laboratoryId: _laboratoryId));
  sl.registerFactory(
    () => EquipmentListBloc(getEquipments: sl(), getEnvironments: sl(), getConnections: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactoryParam<EquipmentDetailBloc, int, void>(
    (id, _) => EquipmentDetailBloc(
      equipmentId: id,
      getEquipment: sl(),
      getEnvironments: sl(),
      getConnection: sl(),
      getBpmConfigs: sl(),
      getMaintenance: sl(),
      getTrends: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
      getUserDirectory: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => TelemetryDashboardBloc(
      getEquipments: sl(),
      getEnvironments: sl(),
      getConnection: sl(),
      getMeasurements: sl(),
      getProfile: sl(),
      getActuations: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => TelemetryHistoryBloc(
      getEquipments: sl(),
      getEnvironments: sl(),
      getMeasurements: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => AlertsBloc(getEnvironments: sl(), getEquipments: sl(), getAlerts: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactoryParam<AlertDetailBloc, int, void>(
    (id, _) => AlertDetailBloc(
      alertId: id,
      getAlert: sl(),
      getEquipment: sl(),
      getEnvironments: sl(),
      getUserDirectory: sl(),
      acknowledge: sl(),
      resolve: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => NotificationsBloc(
      getNotifications: sl(),
      markRead: sl(),
      markAllRead: sl(),
      onReadChanged: () => sl<UnreadNotificationsController>().refresh(),
    ),
  );
  sl.registerFactory(() => NotificationPreferencesBloc(getPreferences: sl(), updatePreferences: sl()));
  sl.registerFactory(() => BatchesBloc(getBatches: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<BatchDetailBloc, int, void>(
    (id, _) => BatchDetailBloc(
      batchId: id,
      getTraceability: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
      getUserDirectory: sl(),
      release: sl(),
      reject: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(() => InventoryBloc(getEnvironments: sl(), getMaterials: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<MaterialDetailBloc, int, int?>(
    (id, environmentId) => MaterialDetailBloc(
      materialId: id,
      environmentId: environmentId,
      getEnvironments: sl(),
      getMaterials: sl(),
      getMaterial: sl(),
      getReceipts: sl(),
      getMovements: sl(),
      getUsages: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => ReportsBloc(
      getKpiDashboard: sl(),
      getDeviationTrends: sl(),
      getReportHistory: sl(),
      getEnvironments: sl(),
      getEquipments: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(() => BillingBloc(getBillingSummary: sl(), laboratoryId: _laboratoryId));
}
