import 'package:cloud_firestore/cloud_firestore.dart';

class OfferedRide {
  String id;
  String userId;
  String departure;
  String destination;
  Timestamp startTime;
  Timestamp reachTime;
  String genderPreference;
  bool isRequested;
  Timestamp createdAt;
  bool isAccepted;
  bool isConfirmed;
  bool isCompleted;
  bool isCancelled;
  String srideId;
  bool isStarted;
  String reqid;

  OfferedRide(
      {required this.id,
      required this.userId,
      required this.departure,
      required this.destination,
      required this.startTime,
      required this.reachTime,
      required this.genderPreference, // ✅ Enum type
      this.isRequested = false,
      required this.createdAt,
      this.isAccepted = false,
      this.isConfirmed = false,
      this.isCompleted = false,
      this.isCancelled = false,
      this.srideId = '',
      this.isStarted = false,
      this.reqid = ''});

  /// ✅ Convert to Firestore (Enum → String)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'departure': departure,
      'destination': destination,
      'startTime': startTime,
      'reachTime': reachTime,
      'genderPreference': genderPreference, // ✅ Store as string
      'isRequested': isRequested,
      'createdAt': createdAt,
      'isAccepted': isAccepted,
      'isConfirmed': isConfirmed,
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'srideId': srideId,
      'isStarted': isStarted,
      'reqid': reqid
    };
  }

  /// ✅ Convert from Firestore (String → Enum)
  factory OfferedRide.fromMap(Map<String, dynamic> map, String docId) {
    return OfferedRide(
        id: docId,
        userId: map['userId'],
        departure: map['departure'],
        destination: map['destination'],
        startTime: map['startTime'],
        reachTime: map['reachTime'],
        genderPreference: map['genderPreference'] ?? 'Any',
        isRequested: map['isRequested'] ?? false,
        createdAt: map['createdAt'],
        isAccepted: map['isAccepted'] ?? false,
        isConfirmed: map['isConfirmed'] ?? false,
        isCompleted: map['isCompleted'] ?? false,
        isCancelled: map['isCancelled'] ?? false,
        srideId: map['srideId'],
        isStarted: map['isStarted'],
        reqid: map['reqid']);
  }
}
