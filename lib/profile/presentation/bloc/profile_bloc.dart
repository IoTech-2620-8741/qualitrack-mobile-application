import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/profile_use_cases.dart';
import '../../domain/profile.dart';

final class ProfileData extends Equatable {
  const ProfileData({required this.profile, this.photo, this.laboratory});

  final UserProfile profile;
  final Uint8List? photo;
  final Laboratory? laboratory;

  ProfileData copyWith({UserProfile? profile, Uint8List? photo, bool clearPhoto = false}) => ProfileData(
    profile: profile ?? this.profile,
    photo: clearPhoto ? null : (photo ?? this.photo),
    laboratory: laboratory,
  );

  @override
  List<Object?> get props => [profile, photo?.length, photo?.hashCode, laboratory];
}

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

final class ProfileSaved extends ProfileEvent {
  const ProfileSaved(this.data);

  final PersonalData data;

  @override
  List<Object?> get props => [data];
}

final class ProfilePhotoPicked extends ProfileEvent {
  const ProfilePhotoPicked(this.photo);

  final ProfilePhoto photo;

  @override
  List<Object?> get props => [photo];
}

final class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

enum ProfileAction { save, photo, removePhoto }

enum ProfileActionStatus { idle, submitting, success, failure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.remote = const RemoteState(),
    this.actionStatus = ProfileActionStatus.idle,
    this.lastAction,
    this.actionFailure,
  });

  final RemoteState<ProfileData> remote;
  final ProfileActionStatus actionStatus;
  final ProfileAction? lastAction;
  final Failure? actionFailure;

  bool get submitting => actionStatus == ProfileActionStatus.submitting;

  ProfileState copyWith({
    RemoteState<ProfileData>? remote,
    ProfileActionStatus? actionStatus,
    ProfileAction? lastAction,
    Failure? actionFailure,
  }) => ProfileState(
    remote: remote ?? this.remote,
    actionStatus: actionStatus ?? this.actionStatus,
    lastAction: lastAction ?? this.lastAction,
    actionFailure: actionFailure,
  );

  @override
  List<Object?> get props => [remote, actionStatus, lastAction, actionFailure];
}

/// Profile of the signed-in user (Profile context) with the laboratory.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required GetMyProfile getProfile,
    required UpdateMyProfile updateProfile,
    required GetMyPhoto getPhoto,
    required UploadMyPhoto uploadPhoto,
    required RemoveMyPhoto removePhoto,
    required GetLaboratory getLaboratory,
    required LaboratoryId? Function() laboratoryId,
    required void Function(UserProfile profile) onProfileChanged,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       _getPhoto = getPhoto,
       _uploadPhoto = uploadPhoto,
       _removePhoto = removePhoto,
       _getLaboratory = getLaboratory,
       _laboratoryId = laboratoryId,
       _onProfileChanged = onProfileChanged,
       super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileSaved>((e, emit) => _run(emit, ProfileAction.save, (data) async {
      return data.copyWith(profile: await _updateProfile(e.data));
    }));
    on<ProfilePhotoPicked>((e, emit) => _run(emit, ProfileAction.photo, (data) async {
      await _uploadPhoto(e.photo);
      return data.copyWith(profile: await _getProfile(), photo: e.photo.bytes);
    }));
    on<ProfilePhotoRemoved>((e, emit) => _run(emit, ProfileAction.removePhoto, (data) async {
      await _removePhoto();
      return data.copyWith(profile: await _getProfile(), clearPhoto: true);
    }));
  }

  final GetMyProfile _getProfile;
  final UpdateMyProfile _updateProfile;
  final GetMyPhoto _getPhoto;
  final UploadMyPhoto _uploadPhoto;
  final RemoveMyPhoto _removePhoto;
  final GetLaboratory _getLaboratory;
  final LaboratoryId? Function() _laboratoryId;
  final void Function(UserProfile profile) _onProfileChanged;

  Future<void> _onRequested(ProfileRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(remote: state.remote.loading()));
    try {
      final profile = await _getProfile();
      final photo = profile.hasPhoto ? await _optional(() => _getPhoto()) : null;
      final labId = _laboratoryId();
      final laboratory = labId == null ? null : await _optional(() => _getLaboratory(labId));
      _onProfileChanged(profile);
      emit(state.copyWith(remote: state.remote.success(ProfileData(profile: profile, photo: photo, laboratory: laboratory))));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }

  /// The photo and the laboratory are secondary: the profile is shown anyway.
  Future<T?> _optional<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }

  Future<void> _run(
    Emitter<ProfileState> emit,
    ProfileAction action,
    Future<ProfileData> Function(ProfileData current) command,
  ) async {
    final current = state.remote.data;
    if (state.submitting || current == null) return;
    emit(state.copyWith(actionStatus: ProfileActionStatus.submitting, lastAction: action));
    try {
      final updated = await command(current);
      _onProfileChanged(updated.profile);
      emit(state.copyWith(remote: state.remote.success(updated), actionStatus: ProfileActionStatus.success));
    } catch (error) {
      emit(state.copyWith(actionStatus: ProfileActionStatus.failure, actionFailure: ApiExceptionMapper.map(error)));
    }
  }
}
