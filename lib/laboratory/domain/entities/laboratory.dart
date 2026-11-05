import 'package:equatable/equatable.dart';

/// `LaboratoryResource`.
class Laboratory extends Equatable {
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
