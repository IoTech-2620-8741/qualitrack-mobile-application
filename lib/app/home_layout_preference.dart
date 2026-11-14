import 'dart:async';

import 'package:flutter/foundation.dart';

import '../command_center/presentation/screens/command_center_screen.dart';
import '../common/infrastructure/storage/secure_key_value_store.dart';

/// The Home layout the user chose, kept on the device in the keystore, the
/// app's only local storage. It is read once at start; a choice the keystore
/// cannot read leaves the list, and one it cannot save holds until the app
/// closes.
class HomeLayoutPreference extends ValueNotifier<HomeLayout> {
  HomeLayoutPreference(this._store) : super(HomeLayout.list);

  static const String storageKey = 'qualitrack.homeLayout';

  final SecureKeyValueStore _store;

  Future<void> load() async {
    try {
      super.value = HomeLayout.values.asNameMap()[await _store.read(storageKey)] ?? HomeLayout.list;
    } on Exception {
      // An unreadable keystore keeps the list.
    }
  }

  /// Each choice of the user is saved as it is made.
  @override
  set value(HomeLayout layout) {
    super.value = layout;
    _store.write(storageKey, layout.name).ignore();
  }
}
