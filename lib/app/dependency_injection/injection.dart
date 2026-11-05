import 'package:get_it/get_it.dart';

import '../../batch/api/index.dart';
import '../../batch/application/batch_facade_service.dart';
import '../../batch/domain/interfaces/batch_interface.dart';
import '../../batch/infrastructure/data_sources/batch_remote_data_provider.dart';
import '../../batch/infrastructure/repositories/batch_repository.dart';
import '../../batch/presentation/batch_detail/bloc/batch_detail_bloc.dart';
import '../../batch/presentation/batch_list/bloc/batch_list_bloc.dart';
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
import '../../equipment/api/index.dart';
import '../../equipment/application/equipment_facade_service.dart';
import '../../equipment/domain/interfaces/equipment_interface.dart';
import '../../equipment/infrastructure/data_sources/equipment_remote_data_provider.dart';
import '../../equipment/infrastructure/repositories/equipment_repository.dart';
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
import '../../inventory/api/index.dart';
import '../../inventory/application/inventory_facade_service.dart';
import '../../inventory/domain/interfaces/inventory_interface.dart';
import '../../inventory/infrastructure/data_sources/inventory_remote_data_provider.dart';
import '../../inventory/infrastructure/repositories/inventory_repository.dart';
import '../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../inventory/presentation/bloc/material_detail_bloc.dart';
import '../../laboratory/api/index.dart';
import '../../laboratory/application/laboratory_facade_service.dart';
import '../../laboratory/domain/interfaces/laboratory_interface.dart';
import '../../laboratory/infrastructure/data_sources/laboratory_remote_data_provider.dart';
import '../../laboratory/infrastructure/repositories/laboratory_repository.dart';
import '../../laboratory/presentation/bloc/products_bloc.dart';
import '../../profile/application/profile_facade_service.dart';
import '../../profile/domain/interfaces/profile_interface.dart';
import '../../profile/infrastructure/data_sources/profile_remote_data_provider.dart';
import '../../profile/infrastructure/repositories/profile_repository.dart';
import '../../profile/presentation/bloc/current_profile_controller.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../reporting/application/reporting_queries.dart';
import '../../reporting/domain/reporting.dart';
import '../../reporting/infrastructure/reporting_infrastructure.dart';
import '../../reporting/presentation/bloc/reports_bloc.dart';
import '../../common/domain/failure.dart';
import '../../common/domain/value_objects.dart';
import '../../common/infrastructure/configuration/api_config.dart';
import '../../common/infrastructure/http/api_client.dart';
import '../../common/infrastructure/http/auth_interceptor.dart';
import '../../common/infrastructure/storage/secure_key_value_store.dart';
import '../../subscription/api/index.dart';
import '../../subscription/application/subscription_facade_service.dart';
import '../../subscription/domain/interfaces/subscription_interface.dart';
import '../../subscription/infrastructure/data_sources/subscription_remote_data_provider.dart';
import '../../subscription/infrastructure/repositories/subscription_repository.dart';
import '../../subscription/presentation/bloc/billing_bloc.dart';
import '../../tracking/api/index.dart';
import '../../tracking/application/telemetry_facade_service.dart';
import '../../tracking/domain/interfaces/telemetry_interface.dart';
import '../../tracking/infrastructure/data_sources/telemetry_remote_data_provider.dart';
import '../../tracking/infrastructure/repositories/telemetry_repository.dart';
import '../../tracking/presentation/bloc/telemetry_dashboard_bloc.dart';
import '../../tracking/presentation/bloc/telemetry_history_bloc.dart';

final GetIt sl = GetIt.instance;

/// Composition root. Widgets never call [sl] directly: the router builds
/// BLoCs through the factories registered here.
Future<void> configureDependencies({ApiConfig? config, SecureKeyValueStore? secureStore}) async {
  await sl.reset();

  // Configuration & common infrastructure
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
  sl.registerLazySingleton(() => LaboratoryRemoteDataProvider(sl()));
  sl.registerLazySingleton<LaboratoryInterface>(() => LaboratoryRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => LaboratoryFacadeService(repository: sl()));
  sl.registerLazySingleton(() => LaboratoryApi(sl()));

  // Equipment Management
  sl.registerLazySingleton(() => EquipmentRemoteDataProvider(sl()));
  sl.registerLazySingleton<EquipmentInterface>(() => EquipmentRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => EquipmentFacadeService(repository: sl()));
  sl.registerLazySingleton(() => EquipmentApi(sl()));

  // Tracking & Telemetry
  sl.registerLazySingleton(() => TelemetryRemoteDataProvider(sl()));
  sl.registerLazySingleton<TelemetryInterface>(() => TelemetryRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => TelemetryFacadeService(repository: sl()));
  sl.registerLazySingleton(() => TelemetryApi(sl()));

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
  sl.registerLazySingleton(() => BatchRemoteDataProvider(sl()));
  sl.registerLazySingleton<BatchInterface>(() => BatchRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => BatchFacadeService(repository: sl()));
  sl.registerLazySingleton(() => BatchApi(sl()));

  // Inventory Management
  sl.registerLazySingleton(() => InventoryRemoteDataProvider(sl()));
  sl.registerLazySingleton<InventoryInterface>(() => InventoryRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => InventoryFacadeService(repository: sl()));
  sl.registerLazySingleton(() => InventoryApi(sl()));

  // Reporting & Audit
  sl.registerLazySingleton(() => ReportingRemoteDataSource(sl()));
  sl.registerLazySingleton<ReportingRepository>(() => ReportingRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetKpiDashboard(sl()));
  sl.registerLazySingleton(() => GetDeviationTrends(sl()));
  sl.registerLazySingleton(() => GetReportHistory(sl()));
  sl.registerLazySingleton(() => GetEquipmentAuditLogs(sl()));
  sl.registerLazySingleton(() => GetBatchAuditLogs(sl()));

  // Payments & Subscriptions
  sl.registerLazySingleton(() => SubscriptionRemoteDataProvider(sl()));
  sl.registerLazySingleton<SubscriptionInterface>(() => SubscriptionRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => SubscriptionFacadeService(repository: sl()));
  sl.registerLazySingleton(() => SubscriptionApi(sl()));

  // Profile
  sl.registerLazySingleton(() => ProfileRemoteDataProvider(sl()));
  sl.registerLazySingleton<ProfileInterface>(() => ProfileRepository(remoteDataProvider: sl()));
  sl.registerLazySingleton(() => ProfileFacadeService(repository: sl()));
  sl.registerLazySingleton(() => CurrentProfileController(profileService: sl()));

  // Command Center (UI composition)
  sl.registerLazySingleton(
    () => GetCommandCenterSummary(
      laboratoryApi: sl(),
      equipmentApi: sl(),
      telemetryApi: sl(),
      batchApi: sl(),
      getAlerts: sl(),
      inventoryApi: sl(),
      subscriptionApi: sl(),
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
      profileService: sl(),
      laboratoryApi: sl(),
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
  sl.registerFactory(() => ProductsBloc(laboratoryService: sl(), laboratoryId: _laboratoryId));
  sl.registerFactory(
    () => EquipmentListBloc(equipmentService: sl(), laboratoryApi: sl(), telemetryApi: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactoryParam<EquipmentDetailBloc, int, void>(
    (id, _) => EquipmentDetailBloc(
      equipmentId: id,
      equipmentService: sl(),
      laboratoryApi: sl(),
      telemetryApi: sl(),
      getTrends: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => TelemetryDashboardBloc(
      equipmentApi: sl(),
      laboratoryApi: sl(),
      telemetryService: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => TelemetryHistoryBloc(
      equipmentApi: sl(),
      laboratoryApi: sl(),
      telemetryService: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => AlertsBloc(laboratoryApi: sl(), equipmentApi: sl(), getAlerts: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactoryParam<AlertDetailBloc, int, void>(
    (id, _) => AlertDetailBloc(
      alertId: id,
      getAlert: sl(),
      equipmentApi: sl(),
      laboratoryApi: sl(),
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
  sl.registerFactory(() => BatchListBloc(batchService: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<BatchDetailBloc, int, void>(
    (id, _) => BatchDetailBloc(
      batchId: id,
      batchService: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
      laboratoryApi: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(() => InventoryBloc(laboratoryApi: sl(), inventoryService: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<MaterialDetailBloc, int, int?>(
    (id, environmentId) => MaterialDetailBloc(
      materialId: id,
      environmentId: environmentId,
      laboratoryApi: sl(),
      inventoryService: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => ReportsBloc(
      getKpiDashboard: sl(),
      getDeviationTrends: sl(),
      getReportHistory: sl(),
      laboratoryApi: sl(),
      equipmentApi: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(() => BillingBloc(subscriptionService: sl(), laboratoryId: _laboratoryId));
}
