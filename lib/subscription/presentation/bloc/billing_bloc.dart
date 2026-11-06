import '../../../common/domain/failure.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../application/subscription_facade_service.dart';
import '../../domain/entities/billing_summary.dart';

final class BillingRequested extends Equatable {
  const BillingRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class BillingBloc extends Bloc<BillingRequested, RemoteState<BillingSummary>> {
  BillingBloc({
    required SubscriptionFacadeService subscriptionService,
    required LaboratoryId Function() laboratoryId,
  }) : _subscriptionService = subscriptionService,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<BillingRequested>(_onRequested);
  }

  final SubscriptionFacadeService _subscriptionService;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(BillingRequested event, Emitter<RemoteState<BillingSummary>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final summary = await _subscriptionService.getBillingSummary(_laboratoryId());
      final empty = summary.active == null && summary.subscriptions.isEmpty;
      emit(state.success(summary, empty: empty));
    } catch (error) {
      emit(state.failed(Failure.from(error)));
    }
  }
}
