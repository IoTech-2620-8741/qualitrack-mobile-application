import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/actuation_event.dart';
import '../../domain/entities/environmental_state.dart';
import '../../domain/entities/monitored_metric.dart';

/// `ActuationEventResource {id, deviceId, action, triggerMetric, triggerState, result, occurredAt}`.
class ActuationEventModel extends ActuationEvent {
  const ActuationEventModel({
    required super.id,
    required super.deviceId,
    required super.action,
    required super.result,
    super.triggerMetric,
    super.triggerState,
    super.occurredAt,
  });

  factory ActuationEventModel.fromJson(Map<String, dynamic> json) {
    final metric = Json.optString(json, 'triggerMetric');
    final state = Json.optString(json, 'triggerState');
    return ActuationEventModel(
      id: Json.requireInt(json, 'id'),
      deviceId: Json.requireInt(json, 'deviceId'),
      action: Json.requireString(json, 'action'),
      result: Json.requireString(json, 'result'),
      triggerMetric: metric == null ? null : MonitoredMetric.fromCode(metric),
      triggerState: state == null ? null : EnvironmentalState.fromCode(state),
      occurredAt: Json.optDateTime(json, 'occurredAt'),
    );
  }
}
