import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qualitrack_mobile/batch/domain/batch.dart';
import 'package:qualitrack_mobile/batch/infrastructure/batch_infrastructure.dart';
import 'package:qualitrack_mobile/compliance/domain/compliance.dart';
import 'package:qualitrack_mobile/compliance/infrastructure/compliance_infrastructure.dart';
import 'package:qualitrack_mobile/equipment/infrastructure/equipment_infrastructure.dart';
import 'package:qualitrack_mobile/iam/domain/user_role.dart';
import 'package:qualitrack_mobile/iam/infrastructure/iam_dtos.dart';
import 'package:qualitrack_mobile/iam/infrastructure/iam_repositories_impl.dart';
import 'package:qualitrack_mobile/inventory/infrastructure/inventory_infrastructure.dart';
import 'package:qualitrack_mobile/shared/domain/failure.dart';
import 'package:qualitrack_mobile/shared/domain/value_objects.dart';
import 'package:qualitrack_mobile/shared/infrastructure/configuration/api_config.dart';
import 'package:qualitrack_mobile/shared/infrastructure/http/api_exception_mapper.dart';
import 'package:qualitrack_mobile/shared/infrastructure/http/auth_interceptor.dart';
import 'package:qualitrack_mobile/shared/infrastructure/http/json_utils.dart';
import 'package:qualitrack_mobile/subscription/infrastructure/subscription_infrastructure.dart';
import 'package:qualitrack_mobile/tracking/domain/telemetry.dart';
import 'package:qualitrack_mobile/tracking/infrastructure/telemetry_infrastructure.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

DioException _bad(int status, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
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
      expect(ApiExceptionMapper.map(_bad(500, {'code': 'UNEXPECTED_ERROR'})), isA<ServerFailure>());
    });

    test('detects onboarding requirement', () {
      final failure = ApiExceptionMapper.map(
        _bad(403, {'code': 'ONBOARDING_REQUIRED', 'nextStep': 'SUBSCRIPTION'}),
      );
      expect(failure, isA<OnboardingRequiredFailure>());
      expect((failure as OnboardingRequiredFailure).nextStep, 'SUBSCRIPTION');
    });

    test('maps timeouts, connectivity and parsing problems', () {
      DioException of(DioExceptionType type) =>
          DioException(requestOptions: RequestOptions(path: '/x'), type: type);
      expect(ApiExceptionMapper.map(of(DioExceptionType.receiveTimeout)), isA<TimeoutFailure>());
      expect(ApiExceptionMapper.map(of(DioExceptionType.connectionError)), isA<NetworkFailure>());
      expect(ApiExceptionMapper.map(const FormatException('bad')), isA<ParsingFailure>());
      expect(() => Json.asMap([1]), throwsA(isA<ParsingFailure>()));
    });
  });

  group('AuthInterceptor', () {
    test('adds bearer token and reports 401 once per failing request', () async {
      var calls = 0;
      final adapter = _FakeAdapter(statusCode: 401);
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(tokenProvider: () => 'abc', onUnauthorized: () async => calls++),
        );

      await expectLater(dio.get<Object?>('/equipments'), throwsA(isA<DioException>()));

      expect(adapter.lastHeaders['Authorization'], 'Bearer abc');
      expect(calls, 1);
    });

    test('requests marked as public skip authentication and 401 handling', () async {
      var calls = 0;
      final adapter = _FakeAdapter(statusCode: 401);
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(tokenProvider: () => 'abc', onUnauthorized: () async => calls++),
        );

      await expectLater(
        dio.post<Object?>(
          '/authentication/sign-in',
          options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(adapter.lastHeaders.containsKey('Authorization'), isFalse);
      expect(calls, 0);
    });
  });

  group('DTO mapping', () {
    test('authenticated user → session', () {
      final dto = AuthenticatedUserDto.fromJson({
        'id': 42,
        'username': 'qa@lab.test',
        'token': fakeJwt(expiresAt: DateTime.utc(2030)),
        'roles': ['ROLE_QA_MANAGER'],
        'laboratoryId': 7,
      });
      final session = dto.toDomain();
      expect(session.userId, 42);
      expect(session.roles, [UserRole.qaManager]);
      expect(session.laboratoryId, const LaboratoryId(7));
      expect(session.token.expiresAt, DateTime.utc(2030));
    });

    test('deviation alert and update request', () {
      final alert = const DeviationAlertDto(alertJson).toDomain();
      expect(alert.status, AlertStatus.unresolved);
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.recordedValue, 40);
      expect(alert.timestamp, DateTime.utc(2026, 9, 3, 17, 1, 24));
      expect(
        const UpdateAlertStatusRequest(status: AlertStatus.resolved, performedBy: 42, resolutionNotes: 'Calibrated')
            .toJson(),
        {'status': 'RESOLVED', 'performedBy': 42, 'resolutionNotes': 'Calibrated'},
      );
    });

    test('batch and status update request', () {
      final batch = const BatchDto({
        'id': 3,
        'labId': 7,
        'productId': 1,
        'productName': 'Mentafetamina',
        'batchNumber': 'LOT-2026-123',
        'quantity': 2.0,
        'unit': 'units',
        'status': 'IN_PROGRESS',
        'startDate': '2026-09-04',
        'endDate': null,
        'notes': null,
      }).toDomain();
      expect(batch.status, BatchStatus.inProgress);
      expect(
        const UpdateBatchStatusRequest.reject(rejectionDate: '2026-09-04', reason: 'BPM').toJson(),
        {'status': 'REJECTED', 'rejectionDate': '2026-09-04', 'reason': 'BPM'},
      );
    });

    test('telemetry, equipment, inventory and subscription resources', () {
      final status = const TelemetryStatusDto({
        'id': null,
        'equipmentId': 5,
        'isOnline': false,
        'currentStatus': 'OFFLINE',
        'lastHeartbeat': null,
        'createdAt': null,
      }).toDomain();
      expect(status.currentStatus, TelemetryStatus.offline);

      final point = const TelemetryHistoryPointDto({
        'id': 1,
        'equipmentId': 5,
        'parameterName': 'Temperature',
        'recordedValue': 38.6,
        'timestamp': 'not-a-date',
        'isAnomaly': true,
      }).toDomain();
      expect(point.timestamp, isNull);
      expect(point.rawTimestamp, 'not-a-date');

      final equipment = const EquipmentDto({
        'id': 5,
        'laboratoryId': 7,
        'name': 'Balance',
        'status': 'CALIBRATING',
      }).toDomain();
      expect(equipment.rawStatus, 'CALIBRATING');
      expect(equipment.hasSensor, isFalse);

      final material = const InventoryMaterialDto({
        'id': 1,
        'laboratoryId': 7,
        'code': 'FE',
        'name': 'Hierro',
        'unit': 'g',
        'minimumStock': 5,
        'usableStock': '3.5',
        'physicalStock': 10,
        'legacyId': null,
      }).toDomain();
      expect(material.usableStock, 3.5);

      final payment = const PaymentDto({
        'id': 1,
        'subscriptionId': 9,
        'provider': 'STRIPE',
        'amount': 199,
        'currency': 'usd',
        'status': 'PAID',
        'paidAt': '2026-06-30T10:00:00Z',
      }).toDomain();
      expect(payment.amount, 199);
      expect(toIsoMillis(DateTime.utc(2026, 6, 14, 15, 50, 0, 0, 123)), '2026-06-14T15:50:00.000Z');
    });
  });

  group('Repositories', () {
    test('secure session repository round-trips the session', () async {
      final store = InMemorySecureStore();
      final repo = SecureSessionRepository(store);
      final session = sessionFixture();
      await repo.save(session);
      expect(store.values.keys, [SecureSessionRepository.storageKey]);
      expect(await repo.load(), session);
      await repo.clear();
      expect(await repo.load(), isNull);
    });

    test('corrupted stored session is discarded', () async {
      final store = InMemorySecureStore()..values[SecureSessionRepository.storageKey] = '{broken';
      expect(await SecureSessionRepository(store).load(), isNull);
      expect(store.values, isEmpty);
    });

    test('compliance repository sends the lifecycle command', () async {
      final client = MockApiClient();
      when(() => client.patch('/deviation-alerts/2', body: any(named: 'body')))
          .thenAnswer((_) async => {...alertJson, 'status': 'ACKNOWLEDGED', 'acknowledgedBy': 42});
      final repo = ComplianceRepositoryImpl(ComplianceRemoteDataSource(client));

      final alert = await repo.acknowledge(alertId: 2, performedBy: 42);

      expect(alert.status, AlertStatus.acknowledged);
      verify(
        () => client.patch(
          '/deviation-alerts/2',
          body: {'status': 'ACKNOWLEDGED', 'performedBy': 42, 'resolutionNotes': null},
        ),
      ).called(1);
    });

    test('repositories filter data of other laboratories', () async {
      final client = MockApiClient();
      when(() => client.get('/equipments', query: {'labId': 7})).thenAnswer(
        (_) async => [
          {'id': 1, 'laboratoryId': 7, 'name': 'A', 'status': 'OPERATIONAL'},
          {'id': 2, 'laboratoryId': 8, 'name': 'B', 'status': 'OPERATIONAL'},
        ],
      );
      final repo = EquipmentRepositoryImpl(EquipmentRemoteDataSource(client));
      final items = await repo.getByLaboratory(const LaboratoryId(7));
      expect(items.map((e) => e.id), [1]);
    });

    test('missing active subscription (404) becomes null', () async {
      final client = MockApiClient();
      when(() => client.get('/laboratories/7/subscriptions', query: {'status': 'ACTIVE'}))
          .thenThrow(const NotFoundFailure());
      final repo = SubscriptionRepositoryImpl(SubscriptionRemoteDataSource(client));
      expect(await repo.getActive(const LaboratoryId(7)), isNull);
    });

    test('inventory data source uses the laboratory scoped path', () async {
      final client = MockApiClient();
      when(() => client.get('/laboratories/7/inventory/materials/1/movements'))
          .thenAnswer((_) async => <Object>[]);
      final repo = InventoryRepositoryImpl(InventoryRemoteDataSource(client));
      expect(await repo.getMovements(const LaboratoryId(7), 1), isEmpty);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.statusCode});

  final int statusCode;
  Map<String, dynamic> lastHeaders = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
