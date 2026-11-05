/// Public entry point of the Compliance and alerts context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

export '../application/compliance_queries.dart';
export '../domain/compliance.dart';
