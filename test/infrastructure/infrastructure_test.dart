import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/entities/batch_status.dart';
import 'package:qualitrack_mobile/batch/infrastructure/data_sources/batch_remote_data_provider.dart';
import 'package:qualitrack_mobile/batch/infrastructure/models/batch_traceability_model.dart';
import 'package:qualitrack_mobile/batch/infrastructure/repositories/batch_repository.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_origin.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_severity.dart';
import 'package:qualitrack_mobile/compliance/domain/entities/alert_status.dart';
import 'package:qualitrack_mobile/compliance/infrastructure/data_sources/compliance_remote_data_provider.dart';
import 'package:qualitrack_mobile/compliance/infrastructure/models/app_notification_model.dart';
import 'package:qualitrack_mobile/compliance/infrastructure/models/deviation_alert_model.dart';
import 'package:qualitrack_mobile/compliance/infrastructure/repositories/compliance_repository.dart';
import 'package:qualitrack_mobile/equipment/domain/entities/equipment_status.dart';
import 'package:qualitrack_mobile/equipment/infrastructure/data_sources/equipment_remote_data_provider.dart';
import 'package:qualitrack_mobile/equipment/infrastructure/models/equipment_model.dart';
import 'package:qualitrack_mobile/equipment/infrastructure/repositories/equipment_repository.dart';
import 'package:qualitrack_mobile/iam/domain/entities/user_role.dart';
import 'package:qualitrack_mobile/iam/infrastructure/data_sources/iam_local_data_provider.dart';
import 'package:qualitrack_mobile/iam/infrastructure/data_sources/iam_remote_data_provider.dart';
import 'package:qualitrack_mobile/iam/infrastructure/models/authenticated_user_model.dart';
import 'package:qualitrack_mobile/iam/infrastructure/repositories/iam_repository.dart';
import 'package:qualitrack_mobile/inventory/infrastructure/data_sources/inventory_remote_data_provider.dart';
import 'package:qualitrack_mobile/inventory/infrastructure/repositories/inventory_repository.dart';
import 'package:qualitrack_mobile/laboratory/infrastructure/data_sources/laboratory_remote_data_provider.dart';
import 'package:qualitrack_mobile/laboratory/infrastructure/repositories/laboratory_repository.dart';
import 'package:qualitrack_mobile/profile/domain/entities/profile_photo.dart';
import 'package:qualitrack_mobile/profile/infrastructure/data_sources/profile_remote_data_provider.dart';
import 'package:qualitrack_mobile/profile/infrastructure/repositories/profile_repository.dart';
import 'package:qualitrack_mobile/common/domain/failure.dart';
import 'package:qualitrack_mobile/common/domain/value_objects.dart';
import 'package:qualitrack_mobile/common/infrastructure/configuration/api_config.dart';
import 'package:qualitrack_mobile/common/infrastructure/http/api_exception_mapper.dart';
import 'package:qualitrack_mobile/common/infrastructure/http/auth_interceptor.dart';
import 'package:qualitrack_mobile/common/infrastructure/http/json_utils.dart';
import 'package:qualitrack_mobile/subscription/infrastructure/data_sources/subscription_remote_data_provider.dart';
import 'package:qualitrack_mobile/subscription/infrastructure/repositories/subscription_repository.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/environmental_state.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/monitored_metric.dart';
import 'package:qualitrack_mobile/tracking/domain/entities/telemetry_target.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/data_sources/telemetry_remote_data_provider.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/models/device_connection_model.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/models/environmental_profile_model.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/models/measurement_model.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/repositories/telemetry_repository.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

DioException _bad(int status, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: status, data: body),
  type: DioExceptionType.badResponse,
);

const lab = LaboratoryId(7);

void main() {
  setUpAll(() => registerFallbackValue(Uint8List(0)));

  group('ApiConfig', () {
    test('normalizes the base url to /api/v1', () {
      expect(const ApiConfig(baseUrl: 'http://10.0.2.2:8080/').apiBaseUrl, 'http://10.0.2.2:8080/api/v1');
      expect(const ApiConfig(baseUrl: 'https://api.test/api/v1').apiBaseUrl, 'https://api.test/api/v1');
      expect(const ApiConfig(baseUrl: '').isConfigured, isFalse);
    });
  });

  group('ApiExceptionMapper', () {
    test('maps HTTP statuses and QualiTrack ErrorResource', () {
      final failure = ApiExceptionMapper.map(
        _bad(400, {'code': 'VALIDATION_ERROR', 'message': 'Validation failed', 'details': 'Batch is already released'}),
      );
      expect(failure, isA<BadRequestFailure>());
      expect(failure.code, 'VALIDATION_ERROR');
      expect(failure.message, contains('Batch is already released'));

      expect(ApiExceptionMapper.map(_bad(401, '<html>Unauthorized</html>')), isA<UnauthorizedFailure>());
      expect(ApiExceptionMapper.map(_bad(403, {'code': 'ACCESS_DENIED'})), isA<ForbiddenFailure>());
      expect(ApiExceptionMapper.map(_bad(404, null)), isA<NotFoundFailure>());
      expect(ApiExceptionMapper.map(_bad(409, {'code': 'INVENTORY_CONFLICT'})), isA<ConflictFailure>());
      expect(ApiExceptionMapper.map(_bad(413, null)).code, 'PAYLOAD_TOO_LARGE');
      expect(ApiExceptionMapper.map(_bad(415, null)).code, 'UNSUPPORTED_MEDIA_TYPE');
      expect(ApiExceptionMapper.map(_bad(502, null)), isA<ServerFailure>());
    });

    test('detects onboarding requirement, including the password change', () {
      final failure = ApiExceptionMapper.map(_bad(403, {'code': 'ONBOARDING_REQUIRED', 'nextStep': 'PASSWORD_CHANGE'}));
      expect(failure, isA<OnboardingRequiredFailure>());
      expect((failure as OnboardingRequiredFailure).nextStep, 'PASSWORD_CHANGE');
    });

    test('maps timeouts, connectivity and parsing problems', () {
      DioException of(DioExceptionType type) => DioException(requestOptions: RequestOptions(path: '/x'), type: type);
      expect(ApiExceptionMapper.map(of(DioExceptionType.receiveTimeout)), isA<TimeoutFailure>());
      expect(ApiExceptionMapper.map(of(DioExceptionType.connectionError)), isA<NetworkFailure>());
      expect(ApiExceptionMapper.map(const FormatException('bad')), isA<ParsingFailure>());
      expect(() => Json.asMap([1]), throwsA(isA<ParsingFailure>()));
      expect(toIsoMillis(DateTime.utc(2026, 6, 14, 15, 50, 0, 0, 123)), '2026-06-14T15:50:00.000Z');
    });
  });

  group('AuthInterceptor', () {
    test('adds bearer token and reports 401 once per failing request', () async {
      var calls = 0;
      final adapter = _FakeAdapter(statusCode: 401);
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(tokenProvider: () => 'abc', onUnauthorized: () async => calls++));

      await expectLater(dio.get<Object?>('/laboratories/7/equipments'), throwsA(isA<DioException>()));

      expect(adapter.lastHeaders['Authorization'], 'Bearer abc');
      expect(calls, 1);
    });

    test('requests marked as public skip authentication and 401 handling', () async {
      var calls = 0;
      final adapter = _FakeAdapter(statusCode: 401);
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(tokenProvider: () => 'abc', onUnauthorized: () async => calls++));

      await expectLater(
        dio.post<Object?>('/authentication/sign-in', options: Options(extra: {AuthInterceptor.skipAuthKey: true})),
        throwsA(isA<DioException>()),
      );

      expect(adapter.lastHeaders.containsKey('Authorization'), isFalse);
      expect(calls, 0);
    });
  });

  group('DTO mapping', () {
    test('authenticated user → session with the temporary password flag', () {
      final session = AuthenticatedUserModel.fromJson({
        'id': 42,
        'username': 'lucia@senkalab.test',
        'token': fakeJwt(expiresAt: DateTime.utc(2030)),
        'roles': ['ROLE_LAB_OPERATOR'],
        'laboratoryId': 7,
        'passwordChangeRequired': true,
      });
      expect(session.userId, 42);
      expect(session.roles, [UserRole.labOperator]);
      expect(session.laboratoryId, lab);
      expect(session.passwordChangeRequired, isTrue);
      expect(session.token.expiresAt, DateTime.utc(2030));
    });

    test('deviation alert with its related automatic actions', () {
      final alert = DeviationAlertModel.fromJson(alertJson);
      expect(alert.status, AlertStatus.unresolved);
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.origin, AlertOrigin.container);
      expect(alert.environmentId, 3);
      expect(alert.deviationCount, 3);
      expect(alert.lastDetectedAt, DateTime.utc(2026, 9, 3, 17, 21, 24));
      expect(alert.relatedActuations.single.action, 'COOLING_ON');
    });

    test('measurement, profile and connection of Tracking', () {
      final measurement = MeasurementModel.fromJson(const {
        'id': 1,
        'deviceId': 10,
        'environmentId': 3,
        'metric': 'HUMIDITY',
        'value': 71.2,
        'textValue': null,
        'unit': '%RH',
        'measuredAt': '2026-10-05T12:00:00Z',
        'state': 'WARNING',
        'thresholdValue': 70,
        'profileVersion': 2,
      });
      expect(measurement.metric, MonitoredMetric.humidity);
      expect(measurement.state, EnvironmentalState.warning);
      expect(measurement.isNumeric, isTrue);

      final profile = EnvironmentalProfileModel.fromJson(const {
        'version': 4,
        'thresholds': [
          {'metric': 'TEMPERATURE', 'unit': '°C', 'normalMin': 2, 'normalMax': 8, 'criticalMin': 0, 'criticalMax': 10},
        ],
        'actuationRules': [
          {'metric': 'TEMPERATURE', 'state': 'CRITICAL', 'action': 'COOLING_ON'},
        ],
        'updatedAt': null,
      });
      expect(profile.thresholdFor(MonitoredMetric.temperature)?.criticalMax, 10);
      expect(profile.actuationRules.single.state, EnvironmentalState.critical);

      final connection = DeviceConnectionModel.fromJson(const {
        'deviceId': 10,
        'connectionStatus': 'REQUIRES_REVIEW',
        'lastCommunicationAt': null,
        'expectedPeriodSeconds': 300,
      });
      expect(connection.isConnected, isFalse);
    });

    test('equipment, batch traceability and notifications', () {
      final equipment = EquipmentModel.fromJson(const {
        'id': 5,
        'laboratoryId': 7,
        'environmentId': null,
        'name': 'Balance',
        'status': 'CALIBRATING',
        'deviceType': null,
      });
      expect(equipment.rawStatus, 'CALIBRATING');
      expect(equipment.isIotDevice, isFalse);

      final traceability = BatchTraceabilityModel.fromJson(const {
        'batch': {
          'id': 3,
          'labId': 7,
          'environmentId': 4,
          'productId': 1,
          'productName': 'Ibuprofen',
          'batchNumber': 'LOT-1',
          'quantity': 2,
          'unit': 'units',
          'status': 'RELEASED',
          'startDate': '2026-09-04',
        },
        'product': {'id': 1, 'code': 'IBU-400', 'name': 'Ibuprofen'},
        'rawMaterials': [],
        'equipment': [
          {'id': 1, 'batchId': 3, 'equipmentId': 9, 'equipmentName': 'Mixer', 'registeredByUserId': 42, 'registeredAt': '2026-09-04T10:00:00Z'},
        ],
        'staff': [],
        'release': {'signedByUserId': 42, 'signatureHash': 'ab12', 'signedAt': '2026-09-05T10:00:00Z'},
        'rejection': null,
        'container': null,
      });
      expect(traceability.batch.status, BatchStatus.released);
      expect(traceability.productCode, 'IBU-400');
      expect(traceability.equipment.single.equipmentName, 'Mixer');
      expect(traceability.release?.signatureHash, 'ab12');
      expect(traceability.rejection, isNull);

      final notification = AppNotificationModel.fromJson(const {
        'id': 1,
        'type': 'ALERT_ESCALATED',
        'severity': 'CRITICAL',
        'subjectType': 'ALERT',
        'subjectId': 9,
        'readAt': null,
      });
      expect(notification.isAboutAlert, isTrue);
      expect(notification.isRead, isFalse);
    });
  });

  group('Repositories', () {
    late MockApiClient client;

    setUp(() => client = MockApiClient());

    test('secure session repository round-trips the session', () async {
      final store = InMemorySecureStore();
      final repo = IamRepository(remoteDataProvider: IamRemoteDataProvider(MockApiClient()), localDataProvider: IamLocalDataProvider(store));
      final session = sessionFixture(passwordChangeRequired: true);
      await repo.saveSession(session);
      expect(store.values.keys, [IamLocalDataProvider.storageKey]);
      // The stored session comes back as the model, so compare the data.
      expect((await repo.loadSession())?.props, session.props);
      await repo.clearSession();
      expect(await repo.loadSession(), isNull);
    });

    test('corrupted stored session is discarded', () async {
      final store = InMemorySecureStore()..values[IamLocalDataProvider.storageKey] = '{broken';
      expect(await IamRepository(remoteDataProvider: IamRemoteDataProvider(MockApiClient()), localDataProvider: IamLocalDataProvider(store)).loadSession(), isNull);
      expect(store.values, isEmpty);
    });

    test('alert lifecycle uses the acknowledgement and resolution sub-resources', () async {
      when(() => client.post('/deviation-alerts/2/acknowledgements')).thenAnswer(
        (_) async => {...alertJson, 'status': 'ACKNOWLEDGED', 'acknowledgedBy': 42},
      );
      when(() => client.post('/deviation-alerts/2/resolutions', body: {'resolutionNotes': 'Door closed'})).thenAnswer(
        (_) async => {...alertJson, 'status': 'RESOLVED'},
      );
      final repo = ComplianceRepository(remoteDataProvider: ComplianceRemoteDataProvider(client));

      expect((await repo.acknowledge(2)).status, AlertStatus.acknowledged);
      expect((await repo.resolve(2, 'Door closed')).status, AlertStatus.resolved);
    });

    test('alerts, equipment and batches use the laboratory routes', () async {
      when(() => client.get('/laboratories/7/environments/3/deviation-alerts')).thenAnswer((_) async => [alertJson]);
      when(() => client.get('/laboratories/7/equipments')).thenAnswer(
        (_) async => [
          {'id': 1, 'laboratoryId': 7, 'name': 'A', 'status': 'OPERATIONAL'},
          {'id': 2, 'laboratoryId': 8, 'name': 'B', 'status': 'OPERATIONAL'},
        ],
      );
      when(() => client.get('/laboratories/7/batches')).thenAnswer((_) async => <Object>[]);

      expect(await ComplianceRepository(remoteDataProvider: ComplianceRemoteDataProvider(client)).getEnvironmentAlerts(lab, 3), hasLength(1));
      expect(
        (await EquipmentRepository(remoteDataProvider: EquipmentRemoteDataProvider(client)).getByLaboratory(lab)).map((e) => e.id),
        [1],
      );
      expect(await BatchRepository(remoteDataProvider: BatchRemoteDataProvider(client)).getByLaboratory(lab), isEmpty);
    });

    test('maintenance is read in the environment of the equipment', () async {
      when(() => client.get('/laboratories/7/environments/3/equipments/10/maintenance-records'))
          .thenAnswer((_) async => <Object>[]);
      final repo = EquipmentRepository(remoteDataProvider: EquipmentRemoteDataProvider(client));
      expect(await repo.getMaintenance(lab, 3, 10), isEmpty);
      expect(EquipmentStatus.fromCode('MAINTENANCE'), EquipmentStatus.maintenance);
    });

    test('batch decisions go to the releases and rejections of the batch', () async {
      const path = '/laboratories/7/environments/4/products/1/batches/3';
      when(() => client.post('$path/releases', body: {'releaseDate': '2026-09-04', 'notes': 'OK'}))
          .thenAnswer((_) async => <String, Object>{});
      when(() => client.post('$path/rejections', body: {'rejectionDate': '2026-09-04', 'reason': 'BPM'}))
          .thenAnswer((_) async => <String, Object>{});
      final repo = BatchRepository(remoteDataProvider: BatchRemoteDataProvider(client));

      await repo.release(lab, batchFixture(), releaseDate: '2026-09-04', notes: 'OK');
      await repo.reject(lab, batchFixture(), rejectionDate: '2026-09-04', reason: 'BPM');

      verify(() => client.post('$path/releases', body: any(named: 'body'))).called(1);
      verify(() => client.post('$path/rejections', body: any(named: 'body'))).called(1);
    });

    test('environmental devices read per environment, container monitors per monitor', () async {
      const from = '2026-10-05T00:00:00.000Z';
      const to = '2026-10-05T12:00:00.000Z';
      when(() => client.get('/laboratories/7/environments/3/telemetry-measurements', query: {'from': from, 'to': to}))
          .thenAnswer((_) async => <Object>[]);
      when(() => client.get(
            '/laboratories/7/environments/3/container-monitors/10/telemetry-measurements',
            query: {'from': from, 'to': to},
          )).thenAnswer((_) async => <Object>[]);
      final repo = TelemetryRepository(remoteDataProvider: TelemetryRemoteDataProvider(client));
      final start = DateTime.utc(2026, 10, 5);
      final end = DateTime.utc(2026, 10, 5, 12);

      await repo.getMeasurements(lab, const TelemetryTarget(deviceId: 1, environmentId: 3, containerMonitor: false), from: start, to: end);
      await repo.getMeasurements(lab, const TelemetryTarget(deviceId: 10, environmentId: 3, containerMonitor: true), from: start, to: end);

      verify(() => client.get('/laboratories/7/environments/3/telemetry-measurements', query: any(named: 'query'))).called(1);
      verify(() => client.get(
            '/laboratories/7/environments/3/container-monitors/10/telemetry-measurements',
            query: any(named: 'query'),
          )).called(1);
    });

    test('a device without profile (404) has a null profile', () async {
      when(() => client.get('/laboratories/7/environments/3/devices/10/environmental-profile'))
          .thenThrow(const NotFoundFailure());
      final repo = TelemetryRepository(remoteDataProvider: TelemetryRemoteDataProvider(client));
      expect(
        await repo.getProfile(lab, const TelemetryTarget(deviceId: 10, environmentId: 3, containerMonitor: true)),
        isNull,
      );
    });

    test('inventory, laboratory and subscription use their current routes', () async {
      when(() => client.get('/laboratories/7/environments/3/raw-materials/1/movements')).thenAnswer((_) async => <Object>[]);
      when(() => client.get('/laboratories/7/environments')).thenAnswer(
        (_) async => [
          {'id': 3, 'laboratoryId': 7, 'code': 'ALM-01', 'name': 'Cold storage', 'usage': 'PRODUCT_STORAGE'},
          {'id': 9, 'laboratoryId': 8, 'code': 'X', 'name': 'Other lab'},
        ],
      );
      when(() => client.get('/laboratories/7/subscriptions')).thenAnswer(
        (_) async => [
          {'id': 1, 'laboratoryId': 7, 'planCode': 'BASIC', 'billingCycle': 'MONTHLY', 'status': 'ACTIVE', 'cancelAtPeriodEnd': true},
        ],
      );

      expect(await InventoryRepository(remoteDataProvider: InventoryRemoteDataProvider(client)).getMovements(lab, materialFixture()), isEmpty);
      expect(
        (await LaboratoryRepository(remoteDataProvider: LaboratoryRemoteDataProvider(client)).getEnvironments(lab)).map((e) => e.code),
        ['ALM-01'],
      );
      final subscriptions = await SubscriptionRepository(remoteDataProvider: SubscriptionRemoteDataProvider(client)).getSubscriptions(lab);
      expect(subscriptions.single.cancelAtPeriodEnd, isTrue);
    });

    test('profile photo is sent as the raw image with its media type', () async {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      when(() => client.putBytes('/users/me/profile/photo', any(), contentType: 'image/jpeg'))
          .thenAnswer((_) async => <String, Object>{});
      when(() => client.getBytes('/users/me/profile/photo')).thenThrow(const NotFoundFailure());
      final repo = ProfileRepository(remoteDataProvider: ProfileRemoteDataProvider(client));

      await repo.uploadMyPhoto(ProfilePhoto(bytes: bytes, contentType: 'image/jpeg'));

      verify(() => client.putBytes('/users/me/profile/photo', bytes, contentType: 'image/jpeg')).called(1);
      expect(await repo.getMyPhoto(), isNull);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.statusCode});

  final int statusCode;
  Map<String, dynamic> lastHeaders = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastHeaders = Map.of(options.headers);
    return ResponseBody.fromString(
      '{"code":"UNAUTHORIZED"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
