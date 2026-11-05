/// Public entry point of the Laboratory context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

export '../application/laboratory_queries.dart';
export '../domain/laboratory.dart';
