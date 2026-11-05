import 'package:flutter/foundation.dart';

import '../../../common/domain/failure.dart';
import '../../application/profile_facade_service.dart';
import '../../domain/entities/user_profile.dart';

/// Name and photo of the signed-in user shown outside the profile screen
/// (the menu header), as the Web toolbar does.
class CurrentProfileController extends ChangeNotifier {
  CurrentProfileController({required ProfileFacadeService profileService}) : _profileService = profileService;

  final ProfileFacadeService _profileService;

  UserProfile? _profile;
  Uint8List? _photo;
  bool _disposed = false;

  UserProfile? get profile => _profile;
  Uint8List? get photo => _photo;

  Future<void> load() async {
    try {
      final profile = await _profileService.getMyProfile();
      final photo = profile.hasPhoto ? await _profileService.getMyPhoto() : null;
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
      _set(profile, profile.hasPhoto ? await _profileService.getMyPhoto() : null);
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
