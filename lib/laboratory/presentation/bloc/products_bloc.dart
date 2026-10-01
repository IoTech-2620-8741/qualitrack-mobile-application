import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/value_objects.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../application/laboratory_queries.dart';
import '../../domain/laboratory.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

final class ProductsRequested extends ProductsEvent {
  const ProductsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class ProductsQueryChanged extends ProductsEvent {
  const ProductsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ProductsState extends Equatable {
  const ProductsState({this.remote = const RemoteState(), this.query = ''});

  final RemoteState<List<PharmaceuticalProduct>> remote;
  final String query;

  List<PharmaceuticalProduct> get visible =>
      (remote.data ?? const []).where((p) => p.matches(query)).toList(growable: false);

  PharmaceuticalProduct? byId(int id) {
    for (final product in remote.data ?? const <PharmaceuticalProduct>[]) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductsState copyWith({RemoteState<List<PharmaceuticalProduct>>? remote, String? query}) =>
      ProductsState(remote: remote ?? this.remote, query: query ?? this.query);

  @override
  List<Object?> get props => [remote, query];
}

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required GetProducts getProducts, required LaboratoryId Function() laboratoryId})
    : _getProducts = getProducts,
      _laboratoryId = laboratoryId,
      super(const ProductsState()) {
    on<ProductsRequested>(_onRequested);
    on<ProductsQueryChanged>((event, emit) => emit(state.copyWith(query: event.query)));
  }

  final GetProducts _getProducts;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(ProductsRequested event, Emitter<ProductsState> emit) async {
    final current = state.remote;
    emit(state.copyWith(
      remote: event.refresh && current.hasData ? current.refreshingState() : current.loading(),
    ));
    try {
      final products = await _getProducts(_laboratoryId());
      emit(state.copyWith(remote: state.remote.success(products, empty: products.isEmpty)));
    } catch (error) {
      emit(state.copyWith(remote: state.remote.failed(ApiExceptionMapper.map(error))));
    }
  }
}
