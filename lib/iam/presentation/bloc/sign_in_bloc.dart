import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../application/iam_use_cases.dart';
import '../../application/session_controller.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

final class SignInSubmitted extends SignInEvent {
  const SignInSubmitted({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

enum SignInStatus { idle, submitting, success, failure }

final class SignInState extends Equatable {
  const SignInState({this.status = SignInStatus.idle, this.failure});

  final SignInStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({required SignIn signIn, required SessionController session})
    : _signIn = signIn,
      _session = session,
      super(const SignInState()) {
    on<SignInSubmitted>(_onSubmitted);
  }

  final SignIn _signIn;
  final SessionController _session;

  Future<void> _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    if (state.status == SignInStatus.submitting) return;
    emit(const SignInState(status: SignInStatus.submitting));
    try {
      final session = await _signIn(username: event.username, password: event.password);
      emit(const SignInState(status: SignInStatus.success));
      await _session.signedIn(session);
    } catch (error) {
      emit(SignInState(status: SignInStatus.failure, failure: _mapSignInFailure(error)));
    }
  }

  /// The backend answers unknown users with 404 and wrong passwords with 400;
  /// both are shown as "invalid credentials" to avoid user enumeration.
  Failure _mapSignInFailure(Object error) {
    final failure = ApiExceptionMapper.map(error);
    if (failure is NotFoundFailure ||
        (failure is BadRequestFailure && failure.code != 'CREDENTIALS_REQUIRED')) {
      return const UnauthorizedFailure(code: 'INVALID_CREDENTIALS');
    }
    return failure;
  }
}
