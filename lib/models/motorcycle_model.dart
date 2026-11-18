import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType {
  matic('MATIC'),
  kopling('KOPLING');

  const VehicleType(this.value);

  final String value;

  static VehicleType fromValue(String value) {
    return VehicleType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw FormatException('Unknown vehicle type: $value'),
    );
  }
}

class MotorcycleModel {
  const MotorcycleModel({
    required this.bikeId,
    required this.userId,
    required this.brand,
    required this.modelName,
    required this.vehicleType,
    required this.pistonDiameterMm,
    this.createdAt,
  });

  static const supportedBrands = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Vespa',
    'Kawasaki',
  ];

  final String bikeId;
  final String userId;
  final String brand;
  final String modelName;
  final VehicleType vehicleType;
  final double pistonDiameterMm;
  final DateTime? createdAt;

  bool isEligibleFor({
    required VehicleType eventVehicleType,
    required double maxPistonDiameterMm,
  }) {
    return vehicleType == eventVehicleType &&
        pistonDiameterMm <= maxPistonDiameterMm;
  }

  factory MotorcycleModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final pistonDiameter = map['pistonDiameterMm'];
    if (pistonDiameter is! num || pistonDiameter <= 0) {
      throw const FormatException(
        'Missing or invalid "pistonDiameterMm" in motorcycle document.',
      );
    }

    return MotorcycleModel(
      bikeId: documentId,
      userId: _requiredString(map, 'userId'),
      brand: _requiredString(map, 'brand'),
      modelName: _requiredString(map, 'modelName'),
      vehicleType: VehicleType.fromValue(
        _requiredString(map, 'vehicleType'),
      ),
      pistonDiameterMm: pistonDiameter.toDouble(),
      createdAt: _dateTimeOrNull(map['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'bikeId': bikeId,
        'userId': userId,
        'brand': brand,
        'modelName': modelName,
        'vehicleType': vehicleType.value,
        'pistonDiameterMm': pistonDiameterMm,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Missing or invalid "$field" in motorcycle document.',
      );
    }
    return value;
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw const FormatException(
      'Invalid "createdAt" in motorcycle document.',
    );
  }
}
