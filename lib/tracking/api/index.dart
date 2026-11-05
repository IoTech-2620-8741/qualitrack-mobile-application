/// Public entry point of the Telemetry tracking context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

export '../application/telemetry_queries.dart';
export '../domain/telemetry.dart';
