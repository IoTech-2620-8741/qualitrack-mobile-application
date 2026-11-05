import 'package:equatable/equatable.dart';

import 'environment_usage.dart';

/// `EnvironmentResource`: an area of the laboratory (room, warehouse, line)
/// where equipment, materials, products and IoT devices are located.
class LabEnvironment extends Equatable {
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
