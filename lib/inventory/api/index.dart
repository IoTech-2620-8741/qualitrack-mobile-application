/// Public entry point of the Inventory context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

export '../application/inventory_queries.dart';
export '../domain/inventory.dart';
