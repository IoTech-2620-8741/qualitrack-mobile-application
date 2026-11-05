/// Public entry point of the Identity and access context. Other bounded contexts import
/// only this file, never the internals of the context.
library;

export '../domain/user_role.dart';
export '../domain/user_session.dart';
export '../presentation/widgets/role_labels.dart';
