import 'package:equatable/equatable.dart';

import 'lab_environment.dart';
import 'pharmaceutical_product.dart';

/// Products of every environment of the laboratory.
class ProductCatalog extends Equatable {
  const ProductCatalog({required this.environments, required this.products});

  final List<LabEnvironment> environments;
  final List<PharmaceuticalProduct> products;

  LabEnvironment? environment(int id) {
    for (final environment in environments) {
      if (environment.id == id) return environment;
    }
    return null;
  }

  @override
  List<Object?> get props => [environments, products];
}
