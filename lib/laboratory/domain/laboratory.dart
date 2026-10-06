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

/// `EnvironmentUsage` of the backend: what an environment is used for.
enum EnvironmentUsage {
  laboratory('LABORATORY'),
  production('PRODUCTION'),
  rawMaterialStorage('RAW_MATERIAL_STORAGE'),
  productStorage('PRODUCT_STORAGE'),
  other('OTHER'),
  unassigned('');

  const EnvironmentUsage(this.code);

  final String code;

  static EnvironmentUsage fromCode(String? code) {
    for (final value in values) {
      if (value != unassigned && value.code == code) return value;
    }
    return EnvironmentUsage.unassigned;
  }
}

/// `EnvironmentResource`: an area of the laboratory (room, warehouse, line)
/// where equipment, materials, products and IoT devices are located.
final class LabEnvironment extends Equatable {
  const LabEnvironment({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.usage = EnvironmentUsage.unassigned,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final EnvironmentUsage usage;

  String get displayName => '$code · $name';

  static int compare(LabEnvironment a, LabEnvironment b) =>
      a.code.toLowerCase().compareTo(b.code.toLowerCase());

  @override
  List<Object?> get props => [id, code, name, description, usage];
}

/// `PharmaceuticalProductResource`; products are registered per environment.
final class PharmaceuticalProduct extends Equatable {
  const PharmaceuticalProduct({
    required this.id,
    required this.environmentId,
    required this.code,
    required this.name,
    required this.active,
    this.description,
    this.specifications,
  });

  final int id;
  final int environmentId;
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
  List<Object?> get props => [id, environmentId, code, name, description, specifications, active];
}

/// Products of every environment of the laboratory.
final class ProductCatalog extends Equatable {
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

/// `StaffMemberResource`: an operator or auditor registered by the quality
/// manager. [userId] is the account used to sign in.
final class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.fullName,
    required this.active,
    this.position,
    this.email,
    this.accessRole,
    this.userId,
  });

  final int id;
  final String fullName;
  final String? position;
  final String? email;
  final bool active;

  /// `OPERATOR` or `AUDITOR`.
  final String? accessRole;
  final int? userId;

  @override
  List<Object?> get props => [id, fullName, position, email, active, accessRole, userId];
}

abstract interface class LaboratoryRepository {
  Future<Laboratory> getLaboratory(LaboratoryId id);
  Future<List<LabEnvironment>> getEnvironments(LaboratoryId id);
  Future<List<PharmaceuticalProduct>> getProducts(LaboratoryId id, int environmentId);
  Future<List<StaffMember>> getStaff(LaboratoryId id);
}
