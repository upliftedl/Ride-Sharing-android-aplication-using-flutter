import 'package:cloud_firestore/cloud_firestore.dart';

/// model for requested ride
class RequestedRide {
  String id;
  String userId;
  String rideId;
  String departure;
  String destination;
  Timestamp startTime;
  Timestamp reachTime;
  bool isAccepted;
  bool isCompleted;
  bool isCancelled;
  String srideId;
  Timestamp requestedAt;
  String requestDestination;

  RequestedRide(
      {required this.id,
      required this.userId,
      required this.rideId,
      required this.departure,
      required this.destination,
      required this.startTime,
      required this.reachTime,
      this.isAccepted = false,
      required this.requestedAt,
      this.isCompleted = false,
      this.isCancelled = false,
      this.srideId = '',
      this.requestDestination = ''});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'rideId': rideId,
      'departure': departure,
      'destination': destination,
      'startTime': startTime,
      'reachTime': reachTime,
      'isAccepted': isAccepted,
      'requestedAt': requestedAt,
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'srideId': srideId,
      'requestDestination': requestDestination
    };
  }

  factory RequestedRide.fromMap(Map<String, dynamic> map, String docId) {
    return RequestedRide(
      id: docId,
      userId: map['userId'],
      rideId: map['rideId'],
      departure: map['departure'],
      destination: map['destination'],
      startTime: map['startTime'],
      reachTime: map['reachTime'],
      // requesterName: map['requesterName'],
      // requesterPhone: map['requesterPhone'],
      isAccepted: map['isAccepted'] ?? false,
      requestedAt: map['requestedAt'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isCancelled: map['isCancelled'] ?? false,
      srideId: map['srideId'],
      requestDestination: map['requestDestination'],
    );
  }
}
