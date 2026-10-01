import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/get_command_center_summary.dart';

final class CommandCenterRequested extends Equatable {
  const CommandCenterRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class CommandCenterBloc extends Bloc<CommandCenterRequested, RemoteState<CommandCenterSummary>> {
  CommandCenterBloc({
    required GetCommandCenterSummary getSummary,
    required LaboratoryId Function() laboratoryId,
  }) : _getSummary = getSummary,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<CommandCenterRequested>(_onRequested);
  }

  final GetCommandCenterSummary _getSummary;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(
    CommandCenterRequested event,
    Emitter<RemoteState<CommandCenterSummary>> emit,
  ) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      emit(state.success(await _getSummary(_laboratoryId())));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }
}
