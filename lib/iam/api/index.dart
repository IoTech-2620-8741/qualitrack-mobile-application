/// Public entry point of the Identity & Access context. Other bounded contexts
/// import only this file, never the internals of the context.
library;

export '../domain/entities/user_role.dart';
export '../domain/entities/user_session.dart';
