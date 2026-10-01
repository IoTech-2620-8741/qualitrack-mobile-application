import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/application/laboratory_queries.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/iam_use_cases.dart';
import '../../domain/user_account.dart';
import '../../domain/user_session.dart';

final class ProfileData extends Equatable {
  const ProfileData({required this.account, this.laboratory, this.laboratoryFailure});

  final UserAccount account;
  final Laboratory? laboratory;
  final Failure? laboratoryFailure;

  @override
  List<Object?> get props => [account, laboratory, laboratoryFailure];
}

final class ProfileRequested extends Equatable {
  const ProfileRequested();

  @override
  List<Object?> get props => [];
}

class ProfileBloc extends Bloc<ProfileRequested, RemoteState<ProfileData>> {
  ProfileBloc({
    required UserSession Function() session,
    required GetUserAccount getUser,
    required GetLaboratory getLaboratory,
  }) : _session = session,
       _getUser = getUser,
       _getLaboratory = getLaboratory,
       super(const RemoteState()) {
    on<ProfileRequested>(_onRequested);
  }

  final UserSession Function() _session;
  final GetUserAccount _getUser;
  final GetLaboratory _getLaboratory;

  Future<void> _onRequested(ProfileRequested event, Emitter<RemoteState<ProfileData>> emit) async {
    emit(state.loading());
    try {
      final session = _session();
      final account = await _getUser(session.userId);
      Laboratory? laboratory;
      Failure? labFailure;
      final labId = session.laboratoryId;
      if (labId != null) {
        try {
          laboratory = await _getLaboratory(labId);
        } on UnauthorizedFailure {
          rethrow;
        } on Failure catch (f) {
          labFailure = f;
        }
      }
      emit(state.success(ProfileData(
        account: account,
        laboratory: laboratory,
        laboratoryFailure: labFailure,
      )));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }
}
