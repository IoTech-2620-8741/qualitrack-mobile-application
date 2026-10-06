import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../application/iam_use_cases.dart';

final class PasswordChangeSubmitted extends Equatable {
  const PasswordChangeSubmitted({required this.currentPassword, required this.newPassword});

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

enum ChangePasswordStatus { idle, submitting, success, failure }

final class ChangePasswordState extends Equatable {
  const ChangePasswordState({this.status = ChangePasswordStatus.idle, this.failure});

  final ChangePasswordStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

class ChangePasswordBloc extends Bloc<PasswordChangeSubmitted, ChangePasswordState> {
  ChangePasswordBloc({required ChangePassword changePassword})
    : _changePassword = changePassword,
      super(const ChangePasswordState()) {
    on<PasswordChangeSubmitted>(_onSubmitted);
  }

  final ChangePassword _changePassword;

  Future<void> _onSubmitted(PasswordChangeSubmitted event, Emitter<ChangePasswordState> emit) async {
    if (state.status == ChangePasswordStatus.submitting) return;
    emit(const ChangePasswordState(status: ChangePasswordStatus.submitting));
    try {
      await _changePassword(currentPassword: event.currentPassword, newPassword: event.newPassword);
      emit(const ChangePasswordState(status: ChangePasswordStatus.success));
    } catch (error) {
      emit(ChangePasswordState(status: ChangePasswordStatus.failure, failure: ApiExceptionMapper.map(error)));
    }
  }
}
