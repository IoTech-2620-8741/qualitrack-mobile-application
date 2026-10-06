import 'package:flutter/foundation.dart';

import '../../../shared/domain/failure.dart';
import '../../application/profile_use_cases.dart';
import '../../domain/profile.dart';

/// Name and photo of the signed-in user shown outside the profile screen
/// (the menu header), as the Web toolbar does.
class CurrentProfileController extends ChangeNotifier {
  CurrentProfileController({required GetMyProfile getProfile, required GetMyPhoto getPhoto})
    : _getProfile = getProfile,
      _getPhoto = getPhoto;

  final GetMyProfile _getProfile;
  final GetMyPhoto _getPhoto;

  UserProfile? _profile;
  Uint8List? _photo;
  bool _disposed = false;

  UserProfile? get profile => _profile;
  Uint8List? get photo => _photo;

  Future<void> load() async {
    try {
      final profile = await _getProfile();
      final photo = profile.hasPhoto ? await _getPhoto() : null;
      _set(profile, photo);
    } on Failure {
      // The menu falls back to the username of the session.
    }
  }

  /// Called by the profile screen after a change.
  Future<void> changed(UserProfile profile) async {
    if (profile.hasPhoto == (_photo != null) && profile.photoUpdatedAt == _profile?.photoUpdatedAt) {
      _set(profile, _photo);
      return;
    }
    try {
      _set(profile, profile.hasPhoto ? await _getPhoto() : null);
    } on Failure {
      _set(profile, null);
    }
  }

  void reset() => _set(null, null);

  void _set(UserProfile? profile, Uint8List? photo) {
    if (_disposed) return;
    _profile = profile;
    _photo = photo;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
