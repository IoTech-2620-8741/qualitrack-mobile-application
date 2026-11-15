import 'package:equatable/equatable.dart';

/// Personal data the user can change (US: update my personal data).
final class PersonalData extends Equatable {
  const PersonalData({required this.fullName, this.dni, this.phoneNumber, this.location});

  final String fullName;
  final String? dni;
  final String? phoneNumber;
  final String? location;

  @override
  List<Object?> get props => [fullName, dni, phoneNumber, location];
}
