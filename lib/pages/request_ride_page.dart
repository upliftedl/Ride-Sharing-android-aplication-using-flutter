import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/get_ride_Model.dart';

class requestScreen extends StatefulWidget {
  @override
  _GetRideScreenState createState() => _GetRideScreenState();
}

class _GetRideScreenState extends State<requestScreen> {
  String searchQuery = '';
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, bool> rideRequestStatus = {}; // Caching request status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find a Ride"),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
          Container(color: Colors.black.withOpacity(0.5)),
          Column(
            children: [
              const SizedBox(height: 100), // Space for app bar
              _buildSearchBar(),
              Expanded(child: _buildRideList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        style: TextStyle(color: Colors.white), // Set text color to white
        decoration: InputDecoration(
          labelText: "Search by location...",
          labelStyle: TextStyle(color: Colors.white), // Set label color
          prefixIcon: Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.black.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (query) {
          setState(() {
            searchQuery = query.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildRideList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('rides').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        var rides = snapshot.data!.docs;

        // Filter Rides (Remove Expired, Completed & Self-Requested Rides)
        var filteredRides =
            rides.where((ride) {
              String departure = (ride['departure'] ?? '').toLowerCase();
              String destination = (ride['destination'] ?? '').toLowerCase();
              String rideOwnerId = ride['userId'];

              bool isSelfRide = rideOwnerId == user?.uid;
              Timestamp? reachTimestamp = ride['reachTime'] as Timestamp?;
              bool isRideCompleted = ride['isCompleted']; // Completion Check

              bool isRideExpired =
                  reachTimestamp != null &&
                  reachTimestamp.toDate().isBefore(DateTime.now());

              return !isSelfRide &&
                  !isRideExpired &&
                  !isRideCompleted && // Exclude completed rides
                  (departure.contains(searchQuery) ||
                      destination.contains(searchQuery));
            }).toList();

        if (filteredRides.isEmpty) {
          return Center(
            child: Text(
              "No available rides.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredRides.length,
          itemBuilder: (context, index) {
            var ride = filteredRides[index];
            return _buildRideCards(ride);
          },
        );
      },
    );
  }

  Widget _buildRideCards(QueryDocumentSnapshot ride) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(ride['userId'])
              .get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return SizedBox(); // Return empty if data is not available
        }

        String riderName =
            (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ??
            "Unknown";

        return FutureBuilder<bool>(
          future: _checkIfRideRequested(ride.id),
          builder: (context, AsyncSnapshot<bool> requestSnapshot) {
            bool hasRequested = requestSnapshot.data ?? false;
            rideRequestStatus[ride.id] = hasRequested;

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(ride['userId'])
                      .get(),
              builder: (
                context,
                AsyncSnapshot<DocumentSnapshot> ratingSnapshot,
              ) {
                double rating = 0.0;
                if (ratingSnapshot.hasData && ratingSnapshot.data!.exists) {
                  rating =
                      (ratingSnapshot.data!.data()
                              as Map<String, dynamic>)['averageRating']
                          ?.toDouble() ??
                      0.0;
                }

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: Colors.black.withOpacity(0.5),
                  child: ListTile(
                    leading: Icon(Icons.directions_bike, color: Colors.blue),
                    title: Text(
                      "${ride['departure']} → ${ride['destination']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start: ${_formatTimestamp(ride['startTime'])}\n"
                          "End: ${_formatTimestamp(ride['reachTime'])}\n"
                          "Rider: $riderName",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(
                                1,
                              ), // Display rating with 1 decimal
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _buildRequestButton(ride, hasRequested),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestButton(QueryDocumentSnapshot ride, bool hasRequested) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            hasRequested
                ? Colors.grey
                : const Color.fromRGBO(165, 101, 101, 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: hasRequested ? null : () => _requestRide(ride),
      child: Text(
        hasRequested ? "Requested" : "Request Ride",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _requestRide(QueryDocumentSnapshot rides) async {
    if (user == null) return;

    var rideOwnerId = rides['userId'];

    // ✅ Prevent user from requesting their own ride
    if (rideOwnerId == user!.uid) {
      _showCustomPopup(
        icon: Icons.error,
        message: "You cannot request your own ride!",
        iconColor: Colors.red,
      );
      return;
    }

    // ✅ Ask user for destination
    String? userDestination = await _showDestinationDialog();
    if (userDestination == null || userDestination.trim().isEmpty) {
      _showCustomPopup(
        icon: Icons.warning_amber_rounded,
        message: "You must enter a destination!",
        iconColor: Colors.orange,
      );
      return;
    }

    // ✅ Check if the ride is already requested in Firestore
    var existingRequest =
        await FirebaseFirestore.instance
            .collection('requested_rides')
            .where('userId', isEqualTo: user!.uid)
            .where('rideId', isEqualTo: rides.id)
            .get();

    if (existingRequest.docs.isNotEmpty) {
      _showCustomPopup(
        icon: Icons.info,
        message: "You have already requested this ride.",
        iconColor: Colors.orange,
      );
      return;
    }

    // ✅ Check if user profile exists
    var userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    if (!userDoc.exists) {
      _showCustomPopup(
        icon: Icons.warning_amber_rounded,
        message: "Error: User profile not found. Please update your profile.",
        iconColor: Colors.orange,
      );
      return;
    }

    // ✅ Prepare request data
    Timestamp requestedAt = Timestamp.now();
    Timestamp? startTimestamp = rides['startTime'] as Timestamp?;
    Timestamp? reachTimestamp = rides['reachTime'] as Timestamp?;

    RequestedRide requestedRide = RequestedRide(
      id: '',
      userId: user!.uid,
      rideId: rides.id,
      departure: rides['departure'],
      destination: rides['destination'],
      requestDestination: userDestination, // User's entered destination
      startTime: startTimestamp ?? Timestamp.now(),
      reachTime: reachTimestamp ?? Timestamp.now(),
      requestedAt: requestedAt,
    );

    try {
      // ✅ Add ride request to Firestore
      var docRef = await FirebaseFirestore.instance
          .collection('requested_rides')
          .add(requestedRide.toMap());
      await FirebaseFirestore.instance
          .collection('requested_rides')
          .doc(docRef.id)
          .update({'id': docRef.id, 'isRequested': true, 'isConfirmed': false});
      // ✅ Mark ride as requested
      await FirebaseFirestore.instance.collection('rides').doc(rides.id).update(
        {'isCancelled': false},
      );

      _showCustomPopup(
        icon: Icons.check_circle,
        message: "Ride Request Sent Successfully!",
        iconColor: Colors.green,
      );

      // ✅ Update local state
      rideRequestStatus[rides.id] = true;
      setState(() {}); // Refresh UI
    } catch (e) {
      _showCustomPopup(
        icon: Icons.error,
        message: "Error sending ride request: $e",
        iconColor: Colors.red,
      );
    }
  }

  /// **Function to Show Destination Input Dialog**
  Future<String?> _showDestinationDialog() async {
    TextEditingController destinationController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Destination"),
          content: TextField(
            controller: destinationController,
            decoration: InputDecoration(hintText: "Enter your destination"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Cancel
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed:
                  () => Navigator.pop(
                    context,
                    destinationController.text,
                  ), // Confirm
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _showCustomPopup({
    required IconData icon,
    required String message,
    Color iconColor = Colors.green, // Default icon color
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            title: Center(child: Icon(icon, size: 50, color: iconColor)),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), // Close dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor, // Match icon color
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<bool> _checkIfRideRequested(String rideId) async {
    if (user == null) return false;
    if (rideRequestStatus.containsKey(rideId))
      return rideRequestStatus[rideId]!;

    var requestSnapshot =
        await FirebaseFirestore.instance
            .collection('requested_rides')
            .where('userId', isEqualTo: user!.uid)
            .where('rideId', isEqualTo: rideId)
            .get();

    bool hasRequested = requestSnapshot.docs.isNotEmpty;
    rideRequestStatus[rideId] = hasRequested;

    return hasRequested;
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime date = timestamp.toDate();
    String period = date.hour >= 12 ? "PM" : "AM";
    int hour =
        date.hour % 12 == 0 ? 12 : date.hour % 12; // Convert to 12-hour format

    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "$hour:${date.minute.toString().padLeft(2, '0')} $period";
  }
}
