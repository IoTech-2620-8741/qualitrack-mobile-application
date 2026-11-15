import 'package:equatable/equatable.dart';

/// `PharmaceuticalProductResource`; products are registered per environment.
class PharmaceuticalProduct extends Equatable {
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
