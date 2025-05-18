import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'helpSupport.dart';
import 'editProfile.dart';
import 'login_screen.dart';
import 'ride_history.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = "Loading...";
  String userEmail = "No Email";
  String userPhone = "";
  String userGender = "";
  String userDob = "";
  String userAddress = "";
  String profilePicture = "";
  bool isProfileComplete = false; // ✅ Flag to track profile completion

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  var userDoc;
  final User? user = FirebaseAuth.instance.currentUser;

  /// ✅ Fetch user profile details & enforce completion
  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => userEmail = user.email ?? "No Email");
    userDoc = await _firestore.collection("users").doc(user.uid).get();
    if (userDoc.exists) {
      Map<String, dynamic>? data = userDoc.data();
      if (data != null) {
        setState(() {
          userName = data["name"] ?? "";
          userPhone = data["phone"] ?? "";
          userGender = data["gender"] ?? "";
          userDob = data["dob"] ?? "";
          userAddress = data["address"] ?? "";

          profilePicture = data["profilePicture"] ?? "";
          isProfileComplete = data["profileCompleted"] ?? false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Profile"),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent Overlay
          Container(color: Colors.black.withOpacity(0.7)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 120), // Space for app bar
                  _buildProfileHeader(),
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(
                              FirebaseAuth.instance.currentUser?.uid,
                            ) // Get current user's ID
                            .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return SizedBox(); // Return empty if no data is available
                      }

                      double rating =
                          (snapshot.data!.data()
                                  as Map<String, dynamic>)['averageRating']
                              ?.toDouble() ??
                          0.0;

                      return Column(
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 30),
                              SizedBox(width: 8),
                              Text(
                                rating.toStringAsFixed(
                                  1,
                                ), // Show rating with 1 decimal
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Profile details
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileDetails("Phone Number", userPhone),
                        _buildProfileDetails("Gender", userGender),
                        _buildProfileDetails("Date of Birth", userDob),
                        _buildProfileDetails("Address", userAddress),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu options remain centered
                  _buildMenuOption(
                    "Ride History",
                    Icons.history,
                    RideHistoryPage(),
                  ),
                  _buildMenuOption(
                    "Edit Profile",
                    Icons.edit,
                    EditProfileScreen(),
                  ),
                  _buildMenuOption(
                    "Help & Support",
                    Icons.help,
                    HelpAndSupportPage(),
                  ),
                  _buildMenuOption(
                    "Logout",
                    Icons.logout,
                    null,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Profile Header (Profile Picture + Name + Email)
  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ??
                      "https://via.placeholder.com/150",
                ),
              ),
              if (user ==
                  null) // Only show edit icon if it's the current user's profile
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          userName.isNotEmpty ? userName : 'Anonymous',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          userEmail.isNotEmpty ? userEmail : 'No email provided',
          style: TextStyle(fontSize: 16, color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// ✅ Profile Details Section
  Widget _buildProfileDetails(String title, String value) {
    return Align(
      alignment: Alignment.centerLeft, // Align everything to the right
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the right
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text for contrast
            ),
          ),
          const SizedBox(height: 4), // Small spacing between title and value
          Text(
            value.isNotEmpty ? value : "Not Provided",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70, // Slightly transparent white text
            ),
          ),
          const SizedBox(height: 10), // Add spacing before the next item
        ],
      ),
    );
  }

  /// ✅ Menu Options for Profile Actions (Disabled if profile is incomplete)
  Widget _buildMenuOption(
    String title,
    IconData icon,
    Widget? page, {
    bool isLogout = false,
  }) {
    return Card(
      color: Colors.black.withOpacity(0.5),
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          icon,
          color: isProfileComplete ? Colors.blue : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isProfileComplete ? Colors.white : Colors.grey,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap:
            isLogout
                ? _logoutUser // ✅ Call logout function instead of navigating directly
                : isProfileComplete
                ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page!),
                )
                : null, // ✅ Disable if profile is incomplete
      ),
    );
  }

  /// ✅ Log out user and navigate to Login Screen
  void _logoutUser() async {
    await _auth.signOut(); // Sign out from Firebase
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false, // Clears navigation stack
    );
  }
}
