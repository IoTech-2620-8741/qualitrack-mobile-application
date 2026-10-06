import 'package:equatable/equatable.dart';

import '../domain/failure.dart';
import '../infrastructure/http/api_exception_mapper.dart';

/// Result of an independent secondary request.
final class Section<T> extends Equatable {
  const Section(this.items) : failure = null;
  const Section.empty() : items = const [], failure = null;
  const Section.failed(this.failure) : items = const [];

  final List<T> items;
  final Failure? failure;

  static Future<Section<R>> load<R>(Future<List<R>> Function() request) async {
    try {
      return Section<R>(await request());
    } on UnauthorizedFailure {
      rethrow;
    } catch (error) {
      return Section<R>.failed(ApiExceptionMapper.map(error));
    }
  }

  bool get failed => failure != null;

  @override
  List<Object?> get props => [items, failure];
}
