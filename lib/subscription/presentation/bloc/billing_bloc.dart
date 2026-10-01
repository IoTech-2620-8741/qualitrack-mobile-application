import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/billing_queries.dart';

final class BillingRequested extends Equatable {
  const BillingRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class BillingBloc extends Bloc<BillingRequested, RemoteState<BillingSummary>> {
  BillingBloc({
    required GetBillingSummary getBillingSummary,
    required LaboratoryId Function() laboratoryId,
  }) : _getSummary = getBillingSummary,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<BillingRequested>(_onRequested);
  }

  final GetBillingSummary _getSummary;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BillingRequested event, Emitter<RemoteState<BillingSummary>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final summary = await _getSummary(_laboratoryId());
      final empty = summary.active == null && summary.subscriptions.isEmpty;
      emit(state.success(summary, empty: empty));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }
}
