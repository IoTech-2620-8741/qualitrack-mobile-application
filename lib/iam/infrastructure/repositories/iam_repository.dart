import 'dart:convert';

import '../../../common/domain/failure.dart';
import '../../../common/infrastructure/http/json_utils.dart';
import '../../domain/entities/onboarding_state.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/interfaces/iam_interface.dart';
import '../data_sources/iam_local_data_provider.dart';
import '../data_sources/iam_remote_data_provider.dart';
import '../models/authenticated_user_model.dart';

/// Implements [IamInterface]: the REST API for authentication and onboarding,
/// and the keystore for the session.
class IamRepository implements IamInterface {
  const IamRepository({
    required IamRemoteDataProvider remoteDataProvider,
    required IamLocalDataProvider localDataProvider,
  }) : _remote = remoteDataProvider,
       _local = localDataProvider;

  final IamRemoteDataProvider _remote;
  final IamLocalDataProvider _local;

  @override
  Future<UserSession> signIn({required String username, required String password}) =>
      _remote.signIn(username, password);

  @override
  Future<OnboardingState> getOnboarding() => _remote.getOnboarding();

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      _remote.changePassword(currentPassword, newPassword);

  @override
  Future<UserSession?> loadSession() async {
    final raw = await _local.read();
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthenticatedUserModel.fromJson(Json.asMap(jsonDecode(raw)));
    } on FormatException {
      await clearSession();
      return null;
    } on Failure {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(UserSession session) =>
      _local.write(jsonEncode(AuthenticatedUserModel.fromDomain(session).toJson()));

  @override
  Future<void> clearSession() => _local.delete();
}
