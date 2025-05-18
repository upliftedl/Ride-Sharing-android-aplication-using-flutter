class UserModel {
  String uid;
  final String name;
  final String email;
  String phone;
  final String gender;
  final String dob;
  String address;
  final String idProofType; // Aadhaar or License
  final String idProofNumber;
  String profilePicture;
  bool isProfileComplete;
  double rating;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.address,
    required this.idProofType,
    required this.idProofNumber,
    required this.profilePicture,
    required this.isProfileComplete,
    required this.rating,
  });

  /// ✅ Convert UserModel to Firestore JSON
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'address': address,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'profilePicture': profilePicture,
      'isProfileComplete': isProfileComplete,
      'rating': rating,
    };
  }

  /// ✅ Convert Firestore JSON to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      address: map['address'] ?? '',
      idProofType: map['idProofType'] ?? '',
      idProofNumber: map['idProofNumber'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      isProfileComplete: map['ProfileComplete'] ?? false,
      rating: map['rating'] ?? 0.0,
    );
  }
}
