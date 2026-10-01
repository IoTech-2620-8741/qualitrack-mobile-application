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
import '../../iam/presentation/bloc/profile_bloc.dart';
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
Future<void> configureDependencies({
  ApiConfig? config,
  SecureKeyValueStore? secureStore,
}) async {
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
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.create(config: sl(), authInterceptor: sl()),
  );

  // IAM
  sl.registerLazySingleton(() => IamRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<SessionRepository>(() => SecureSessionRepository(sl()));
  sl.registerLazySingleton(() => SignIn(sl(), sl()));
  sl.registerLazySingleton(() => RestoreSession(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => CheckOnboarding(sl()));
  sl.registerLazySingleton(() => GetUserAccount(sl()));
  sl.registerLazySingleton(
    () => SessionController(restoreSession: sl(), signOut: sl(), checkOnboarding: sl()),
  );

  // Laboratory Management
  sl.registerLazySingleton(() => LaboratoryRemoteDataSource(sl()));
  sl.registerLazySingleton<LaboratoryRepository>(() => LaboratoryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLaboratory(sl()));
  sl.registerLazySingleton(() => GetProducts(sl()));

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
  sl.registerLazySingleton(() => GetTelemetryStatus(sl()));
  sl.registerLazySingleton(() => GetTelemetryStatuses(sl()));
  sl.registerLazySingleton(() => GetLatestTelemetry(sl()));
  sl.registerLazySingleton(() => GetTelemetryHistory(sl()));

  // Compliance & Alerting
  sl.registerLazySingleton(() => ComplianceRemoteDataSource(sl()));
  sl.registerLazySingleton<ComplianceRepository>(() => ComplianceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLaboratoryAlerts(sl()));
  sl.registerLazySingleton(() => GetBatchAlerts(sl()));
  sl.registerLazySingleton(() => GetAlertDetail(sl()));
  sl.registerLazySingleton(() => AcknowledgeAlert(sl()));
  sl.registerLazySingleton(() => ResolveAlert(sl()));
  sl.registerLazySingleton(() => GetEquipmentComplianceEvents(sl()));
  sl.registerLazySingleton(() => GetBatchComplianceEvents(sl()));

  // Product Batch Management
  sl.registerLazySingleton(() => BatchRemoteDataSource(sl()));
  sl.registerLazySingleton<BatchRepository>(() => BatchRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBatches(sl()));
  sl.registerLazySingleton(() => GetBatchDetail(sl()));
  sl.registerLazySingleton(() => GetBatchRawMaterials(sl()));
  sl.registerLazySingleton(() => ReleaseExistingBatch(sl()));
  sl.registerLazySingleton(() => RejectExistingBatch(sl()));

  // Inventory Management
  sl.registerLazySingleton(() => InventoryRemoteDataSource(sl()));
  sl.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetInventoryMaterials(sl()));
  sl.registerLazySingleton(() => GetMaterialReceipts(sl()));
  sl.registerLazySingleton(() => GetInventoryMovements(sl()));

  // Reporting & Audit
  sl.registerLazySingleton(() => ReportingRemoteDataSource(sl()));
  sl.registerLazySingleton<ReportingRepository>(() => ReportingRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetKpiDashboard(sl()));
  sl.registerLazySingleton(() => GetReportHistory(sl()));
  sl.registerLazySingleton(() => GetDeviationTrends(sl()));
  sl.registerLazySingleton(() => GetEquipmentAuditLogs(sl()));
  sl.registerLazySingleton(() => GetBatchAuditLogs(sl()));

  // Payments & Subscriptions
  sl.registerLazySingleton(() => SubscriptionRemoteDataSource(sl()));
  sl.registerLazySingleton<SubscriptionRepository>(() => SubscriptionRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBillingSummary(sl()));

  // Command Center (UI composition)
  sl.registerLazySingleton(
    () => GetCommandCenterSummary(
      getLaboratory: sl(),
      getEquipments: sl(),
      getTelemetryStatuses: sl(),
      getBatches: sl(),
      getAlerts: sl(),
      getMaterials: sl(),
      getKpi: sl(),
      getActiveSubscription: (lab) => sl<SubscriptionRepository>().getActive(lab),
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
  sl.registerFactory(() => ProfileBloc(session: _session, getUser: sl(), getLaboratory: sl()));
  sl.registerFactory(() => CommandCenterBloc(getSummary: sl(), laboratoryId: _laboratoryId));
  sl.registerFactory(() => ProductsBloc(getProducts: sl(), laboratoryId: _laboratoryId));
  sl.registerFactory(
    () => EquipmentListBloc(
      getEquipments: sl(),
      getTelemetryStatuses: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactoryParam<EquipmentDetailBloc, int, void>(
    (id, _) => EquipmentDetailBloc(
      equipmentId: id,
      getEquipment: sl(),
      getTelemetryStatus: sl(),
      getBpmConfigs: sl(),
      getMaintenance: sl(),
      getTrends: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
    ),
  );
  sl.registerFactory(
    () => TelemetryDashboardBloc(
      getEquipments: sl(),
      getStatus: sl(),
      getLatest: sl(),
      getHistory: sl(),
      getBpmConfigs: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => TelemetryHistoryBloc(getEquipments: sl(), getHistory: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactory(
    () => AlertsBloc(getEquipments: sl(), getAlerts: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactoryParam<AlertDetailBloc, int, void>(
    (id, _) => AlertDetailBloc(
      alertId: id,
      getAlert: sl(),
      getEquipment: sl(),
      acknowledge: sl(),
      resolve: sl(),
      currentUserId: () => _session().userId,
    ),
  );
  sl.registerFactory(() => BatchesBloc(getBatches: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<BatchDetailBloc, int, void>(
    (id, _) => BatchDetailBloc(
      batchId: id,
      getBatch: sl(),
      getRawMaterials: sl(),
      getAlerts: sl(),
      getEvents: sl(),
      getAuditLogs: sl(),
      release: sl(),
      reject: sl(),
    ),
  );
  sl.registerFactory(() => InventoryBloc(getMaterials: sl(), laboratoryId: _laboratoryId));
  sl.registerFactoryParam<MaterialDetailBloc, int, void>(
    (id, _) => MaterialDetailBloc(
      materialId: id,
      getMaterials: sl(),
      getReceipts: sl(),
      getMovements: sl(),
      laboratoryId: _laboratoryId,
    ),
  );
  sl.registerFactory(
    () => ReportsBloc(getKpiDashboard: sl(), getReportHistory: sl(), laboratoryId: _laboratoryId),
  );
  sl.registerFactory(() => BillingBloc(getBillingSummary: sl(), laboratoryId: _laboratoryId));
}
