import 'dart:convert';

import '../../shared/domain/failure.dart';
import '../../shared/infrastructure/http/json_utils.dart';
import '../../shared/infrastructure/storage/secure_key_value_store.dart';
import '../domain/iam_repositories.dart';
import '../domain/onboarding_state.dart';
import '../domain/user_account.dart';
import '../domain/user_session.dart';
import 'iam_dtos.dart';
import 'iam_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final IamRemoteDataSource _remote;

  @override
  Future<UserSession> signIn({required String username, required String password}) async {
    final dto = await _remote.signIn(username, password);
    return dto.toDomain();
  }

  @override
  Future<OnboardingState> getOnboarding() async => (await _remote.getOnboarding()).toDomain();

  @override
  Future<UserAccount> getUser(int userId) async => (await _remote.getUser(userId)).toDomain();
}

/// Stores the session as a single JSON document inside the platform keystore.
/// Nothing is written to SharedPreferences.
class SecureSessionRepository implements SessionRepository {
  const SecureSessionRepository(this._store);

  static const String storageKey = 'qualitrack.session';

  final SecureKeyValueStore _store;

  @override
  Future<UserSession?> load() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthenticatedUserDto.fromJson(Json.asMap(jsonDecode(raw))).toDomain();
    } on FormatException {
      await clear();
      return null;
    } on Failure {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(UserSession session) =>
      _store.write(storageKey, jsonEncode(AuthenticatedUserDto.fromDomain(session).toJson()));

  @override
  Future<void> clear() => _store.delete(storageKey);
}
