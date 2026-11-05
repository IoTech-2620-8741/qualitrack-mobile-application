import '../../../common/infrastructure/storage/secure_key_value_store.dart';

/// Keeps the session as a single JSON document inside the platform keystore.
/// Nothing is written to SharedPreferences.
class IamLocalDataProvider {
  const IamLocalDataProvider(this._store);

  static const String storageKey = 'qualitrack.session';

  final SecureKeyValueStore _store;

  Future<String?> read() => _store.read(storageKey);

  Future<void> write(String json) => _store.write(storageKey, json);

  Future<void> delete() => _store.delete(storageKey);
}
