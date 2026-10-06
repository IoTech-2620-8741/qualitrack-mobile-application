import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../compliance/application/compliance_queries.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../laboratory/application/laboratory_queries.dart';
import '../../../reporting/application/reporting_queries.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../../tracking/application/telemetry_queries.dart';
import '../../../tracking/domain/telemetry.dart';
import '../../application/equipment_queries.dart';
import '../../domain/equipment.dart';

/// Everything shown on the equipment detail screen. Secondary sections are
/// loaded independently so one failing endpoint does not hide the others.
final class EquipmentDetail extends Equatable {
  const EquipmentDetail({
    required this.equipment,
    this.environmentName,
    this.connection,
    this.bpmConfigs = const Section.empty(),
    this.maintenance = const Section.empty(),
    this.trends = const Section.empty(),
    this.events = const Section.empty(),
    this.auditLogs = const Section.empty(),
    this.people = const {},
  });

  final Equipment equipment;
  final String? environmentName;
  final DeviceConnection? connection;
  final Section<BpmParameterConfig> bpmConfigs;
  final Section<MaintenanceRecord> maintenance;

  /// Deviation indicators of the device in the last 7 days.
  final Section<DeviationTrend> trends;
  final Section<ComplianceEvent> events;
  final Section<AuditLogEntry> auditLogs;
  final Map<int, String> people;

  @override
  List<Object?> get props => [
    equipment,
    environmentName,
    connection,
    bpmConfigs,
    maintenance,
    trends,
    events,
    auditLogs,
    people,
  ];
}

final class EquipmentDetailRequested extends Equatable {
  const EquipmentDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class EquipmentDetailBloc extends Bloc<EquipmentDetailRequested, RemoteState<EquipmentDetail>> {
  EquipmentDetailBloc({
    required this.equipmentId,
    required GetEquipment getEquipment,
    required GetEnvironments getEnvironments,
    required GetDeviceConnection getConnection,
    required GetBpmConfigs getBpmConfigs,
    required GetMaintenanceHistory getMaintenance,
    required GetDeviationTrends getTrends,
    required GetEquipmentComplianceEvents getEvents,
    required GetEquipmentAuditLogs getAuditLogs,
    required GetUserDirectory getUserDirectory,
    required LaboratoryId Function() laboratoryId,
  }) : _getEquipment = getEquipment,
       _getEnvironments = getEnvironments,
       _getConnection = getConnection,
       _getBpmConfigs = getBpmConfigs,
       _getMaintenance = getMaintenance,
       _getTrends = getTrends,
       _getEvents = getEvents,
       _getAuditLogs = getAuditLogs,
       _getUserDirectory = getUserDirectory,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<EquipmentDetailRequested>(_onRequested);
  }

  final int equipmentId;
  final GetEquipment _getEquipment;
  final GetEnvironments _getEnvironments;
  final GetDeviceConnection _getConnection;
  final GetBpmConfigs _getBpmConfigs;
  final GetMaintenanceHistory _getMaintenance;
  final GetDeviationTrends _getTrends;
  final GetEquipmentComplianceEvents _getEvents;
  final GetEquipmentAuditLogs _getAuditLogs;
  final GetUserDirectory _getUserDirectory;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(EquipmentDetailRequested event, Emitter<RemoteState<EquipmentDetail>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      final equipment = await _getEquipment(lab, equipmentId);
      final target = targetOf(equipment);
      final environmentId = equipment.environmentId;
      final results = await Future.wait<Object?>([
        _optional(() async {
          for (final environment in await _getEnvironments(lab)) {
            if (environment.id == environmentId) return environment.displayName;
          }
          return null;
        }),
        target == null ? Future<DeviceConnection?>.value() : _optional(() => _getConnection(lab, target)),
        Section.load(() => _getBpmConfigs(lab, equipmentId)),
        Section.load(() => _getMaintenance(lab, equipment)),
        Section.load(() async {
          if (target == null) return const <DeviationTrend>[];
          final trends = await _getTrends(lab, [target.environmentId], ReportPeriod.last7Days);
          return trends.where((t) => t.equipmentId == equipmentId).toList();
        }),
        Section.load(() => _getEvents(lab, equipmentId)),
        Section.load(() => _getAuditLogs(lab, equipmentId)),
        _optional(() => _getUserDirectory(lab)),
      ]);
      emit(state.success(EquipmentDetail(
        equipment: equipment,
        environmentName: results[0] as String?,
        connection: results[1] as DeviceConnection?,
        bpmConfigs: results[2]! as Section<BpmParameterConfig>,
        maintenance: results[3]! as Section<MaintenanceRecord>,
        trends: results[4]! as Section<DeviationTrend>,
        events: results[5]! as Section<ComplianceEvent>,
        auditLogs: results[6]! as Section<AuditLogEntry>,
        people: (results[7] as Map<int, String>?) ?? const {},
      )));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }

  Future<T?> _optional<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }
}
