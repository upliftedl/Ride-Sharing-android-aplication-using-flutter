// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';

class StartRideModel {
  final String rideId;
  final String driverId;
  final String passengerId;
  final double passengerLat;
  final double passengerLng;
  final double driverLat;
  final double driverLng;
  final double? distanceTraveled;
  final String rideStatus; // "On the way", "Arrived", "Completed"
  final bool isCompleted;
  final bool isCancelled;
  bool isDriverStarted;
  bool ispassengerStarted;

  StartRideModel({
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.passengerLat,
    required this.passengerLng,
    required this.driverLat,
    required this.driverLng,
    this.distanceTraveled,
    required this.rideStatus,
    required this.isCancelled,
    required this.isDriverStarted,
    required this.ispassengerStarted,
    required this.isCompleted,
  });

  /// ✅ `copyWith` to update specific fields
  StartRideModel copyWith({
    double? currentLat,
    double? currentLng,
    double? distanceTraveled,
    String? rideStatus,
    bool? isCompleted,
    bool? isStarted,
  }) {
    return StartRideModel(
      rideId: rideId,
      driverId: driverId,
      passengerId: passengerId,
      passengerLat: passengerLat,
      passengerLng: passengerLng,
      driverLat: driverLat,
      driverLng: driverLng,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      rideStatus: rideStatus ?? this.rideStatus,
      isCancelled: isCancelled,
      isDriverStarted: isDriverStarted,
      ispassengerStarted: ispassengerStarted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// ✅ Convert Firestore document to `StartRideModel`
  factory StartRideModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return StartRideModel(
      rideId: doc.id,
      driverId: data['driverId'] ?? '',
      passengerId: data['passengerId'] ?? '',
      driverLat: (data['driverLat'] ?? 0.0).toDouble(),
      driverLng: (data['driverLng'] ?? 0.0).toDouble(),
      passengerLat: (data['passengerLat'] ?? 0.0).toDouble(),
      passengerLng: (data['passengerLng'] ?? 0.0).toDouble(),
      distanceTraveled:
          data['distanceTraveled'] != null
              ? (data['distanceTraveled'] as num).toDouble()
              : null,
      rideStatus: data['rideStatus'] ?? "Pending",
      isCancelled: data['isConfirmed'] ?? false,
      isDriverStarted: data['isDriverStarted'] ?? false,
      ispassengerStarted: data['ispassengerStarted'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  /// ✅ Convert model to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      "driverId": driverId,
      "passengerId": passengerId,
      "driverLat": driverLat,
      "driverLng": driverLng,
      "passengerLat": passengerLat,
      "passengerLng": passengerLng,
      "distanceTraveled": distanceTraveled,
      "rideStatus": rideStatus,
      "isDriverStarted": isDriverStarted,
      "ispassengerStarted": ispassengerStarted,
      "isCompleted": isCompleted,
    };
  }
}
