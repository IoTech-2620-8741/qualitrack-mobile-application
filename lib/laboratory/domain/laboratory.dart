import 'package:equatable/equatable.dart';

import '../../shared/domain/value_objects.dart';

/// `LaboratoryResource`.
final class Laboratory extends Equatable {
  const Laboratory({
    required this.id,
    required this.name,
    this.ruc,
    this.phone,
    this.address,
    this.status,
    this.applicableRegulations = const [],
  });

  final int id;
  final String name;
  final String? ruc;
  final String? phone;
  final String? address;
  final String? status;
  final List<String> applicableRegulations;

  @override
  List<Object?> get props => [id, name, ruc, phone, address, status, applicableRegulations];
}

/// `PharmaceuticalProductResource` (owned by Laboratory Management).
final class PharmaceuticalProduct extends Equatable {
  const PharmaceuticalProduct({
    required this.id,
    required this.laboratoryId,
    required this.code,
    required this.name,
    required this.active,
    this.description,
    this.specifications,
  });

  final int id;
  final int laboratoryId;
  final String code;
  final String name;
  final String? description;
  final String? specifications;
  final bool active;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        (description?.toLowerCase().contains(q) ?? false);
  }

  @override
  List<Object?> get props => [id, laboratoryId, code, name, description, specifications, active];
}

abstract interface class LaboratoryRepository {
  Future<Laboratory> getLaboratory(LaboratoryId id);
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id);
}
