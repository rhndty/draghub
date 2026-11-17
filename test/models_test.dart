import 'package:draghub/models/motorcycle_model.dart';
import 'package:draghub/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('parses the ERD role values', () {
      final user = UserModel.fromMap({
        'uid': 'user-1',
        'email': 'rider@example.com',
        'fullName': 'Rider',
        'phoneNumber': '08123456789',
        'role': 'anggota',
      });

      expect(user.role, UserRole.member);
      expect(user.createdAt, isNull);
    });

    test('rejects unknown roles rather than silently granting a fallback', () {
      expect(() => UserRole.fromValue('PESERTA'), throwsFormatException);
    });
  });

  group('MotorcycleModel', () {
    const motorcycle = MotorcycleModel(
      bikeId: 'bike-1',
      userId: 'user-1',
      brand: 'Honda',
      modelName: 'Vario 125',
      vehicleType: VehicleType.matic,
      pistonDiameterMm: 62,
    );

    test('matches only eligible event type and piston limit', () {
      expect(
        motorcycle.isEligibleFor(
          eventVehicleType: VehicleType.matic,
          maxPistonDiameterMm: 63,
        ),
        isTrue,
      );
      expect(
        motorcycle.isEligibleFor(
          eventVehicleType: VehicleType.kopling,
          maxPistonDiameterMm: 63,
        ),
        isFalse,
      );
      expect(
        motorcycle.isEligibleFor(
          eventVehicleType: VehicleType.matic,
          maxPistonDiameterMm: 61.9,
        ),
        isFalse,
      );
    });
  });
}
