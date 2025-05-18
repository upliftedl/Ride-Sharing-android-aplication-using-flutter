import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'request_ride_page.dart';
import 'offer_ride_page.dart';
import 'start_ride_page.dart';
import 'editProfile.dart';
import 'profile.dart';
import 'package:uuid/uuid.dart';
import '../models/StartRideModel.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Offered and Requested Rides
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            "Home",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.account_circle, size: 28, color: Colors.white),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  ),
            ),
          ],
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
            Container(color: Colors.black.withOpacity(0.6)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 150), // Space for app bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActionButtons(),
                ),
                const SizedBox(height: 20),
                TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: [
                    Tab(text: "Offered Rides Requests"),
                    Tab(text: "Requested Rides"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildOfferedRides(), // Scrollable ListView
                      _buildRequestedRides(), // Scrollable ListView
                    ],
                  ),
                ),
              ],
            ),
            // Floating Action Button properly placed
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80, right: 16),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: FloatingActionButton(
                    onPressed: () => _makePhoneCall(),
                    child: Icon(Icons.call, color: Colors.white),
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall() async {
    const phoneNumber = 'tel:7034592461'; // Replace with your emergency number
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch emergency call!')),
      );
    }
  }

  /// Action Buttons for offer and request
  Widget _buildActionButtons() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centers content vertically
        crossAxisAlignment:
            CrossAxisAlignment.center, // Aligns buttons to center
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.directions_car, color: Colors.white),
            label: const Text(
              "Offer a Ride",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => _checkProfileCompletion(() => OfferRideScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(165, 101, 101, 0.6),
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              "Get a Ride",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => _checkProfileCompletion(() => requestScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(165, 101, 101, 0.6),
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 53),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///  check profile completion
  void _checkProfileCompletion(Widget Function() destinationScreen) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();
      bool isComplete = userDoc.data()?["profileCompleted"];

      if (isComplete) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationScreen()),
        );
      } else {
        _showProfileIncompleteDialog(); // Don't push as a screen, just call it
      }
    }
  }

  /// profile completion
  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must update profile
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            backgroundColor: Colors.black.withOpacity(
              0.85,
            ), // Dark semi-transparent background
            title: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 50,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Profile Incomplete",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            content: const Text(
              "Please complete your profile before accessing other features.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Update Now",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Fetch Offered Rides

  Widget _buildOfferedRides() {
    if (FirebaseAuth.instance.currentUser == null) {
      return _buildErrorText("Error: User not logged in.");
    }

    return StreamBuilder<List<String>>(
      stream: _getUserRideIdsStream(),
      builder: (context, rideIdSnapshot) {
        if (rideIdSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!rideIdSnapshot.hasData || rideIdSnapshot.data!.isEmpty) {
          print("DEBUG: No rides offered.");
          return _buildErrorText("No rides offered.");
        }

        // Debug print: List of ride IDs
        print("DEBUG: Ride IDs retrieved: ${rideIdSnapshot.data}");

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('requested_rides')
                  .where(
                    'rideId',
                    whereIn: rideIdSnapshot.data,
                  ) // Use rideIdSnapshot.data here
                  .snapshots(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!requestSnapshot.hasData ||
                requestSnapshot.data!.docs.isEmpty) {
              print("DEBUG: No ride requests found.");
              return _buildErrorText("No ride requests found.");
            }

            // Debug print: List of requested ride documents
            print("DEBUG: Requested ride documents retrieved:");
            for (var doc in requestSnapshot.data!.docs) {
              print("DEBUG: ${doc.id} - ${doc.data()}");
            }

            return _buildRideList(requestSnapshot.data!.docs, true);
          },
        );
      },
    );
  }

  Stream<List<String>> _getUserRideIdsStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: user.uid)
        .where('isCompleted', isEqualTo: false) // Exclude completed rides
        .snapshots()
        .map((snapshot) {
          final rideIds = snapshot.docs.map((doc) => doc.id).toList();
          print(
            "DEBUG: _getUserRideIdsStream -> rideIds: $rideIds",
          ); // Debug print
          return rideIds;
        });
  }

  /// offered list
  Widget _buildRideList(List<QueryDocumentSnapshot> rides, bool isOfferedRide) {
    var activeRides =
        rides.where((ride) {
          Timestamp? reachTime = ride['reachTime'] as Timestamp?;
          bool isCompleted = ride['isCompleted'] ?? false;
          bool isCancelled = ride['isCancelled'] ?? false;

          // Exclude completed and cancelled rides
          return reachTime != null &&
              reachTime.toDate().isAfter(DateTime.now()) &&
              !isCompleted &&
              !isCancelled;
        }).toList();

    if (activeRides.isEmpty) {
      return _buildErrorText("No active rides available.");
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeRides.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white70),
      itemBuilder: (context, index) {
        var ride = activeRides[index];
        String id = ride['rideId'];
        String userId = ride['userId'];
        String reqid = ride['id'];
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userSnapshot.hasError ||
                !userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              return const Text(
                "Error loading user data",
                style: TextStyle(color: Colors.red),
              );
            }

            String riderName = userSnapshot.data!['name'] ?? "Unknown";

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('rides').doc(id).get(),
              builder: (context, rideSnapshot) {
                if (rideSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (rideSnapshot.hasError ||
                    !rideSnapshot.hasData ||
                    !rideSnapshot.data!.exists) {
                  return const Text(
                    "Error loading ride data",
                    style: TextStyle(color: Colors.red),
                  );
                }

                var rideDoc = rideSnapshot.data!;
                bool isRequested = ride['isRequested'] ?? false;
                bool isAccepted = ride['isAccepted'] ?? false;
                bool isConfirmed = ride['isConfirmed'] ?? false;
                bool isCancelled = rideDoc['isCancelled'] ?? false;
                bool ridconform = rideDoc['isConfirmed'] ?? false;
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: Colors.black.withOpacity(0.6),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_bike,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "${ride['departure']} ➝ ${ride['destination']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rider: $riderName",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Start: ${_formatTimeOnly(ride['startTime'])}\nEnd: ${_formatTimeOnly(ride['reachTime'])}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Requested location: ${ride['requestDestination']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (isCancelled)
                          const Text(
                            "Request was Cancelled",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRideActionButtons(
                          reqid,
                          id,
                          isRequested,
                          isAccepted,
                          isConfirmed,
                          isCancelled,
                          ridconform,
                        ),
                        if (!isConfirmed)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color.fromARGB(255, 61, 52, 52),
                            ),
                            tooltip: "Cancel Ride",
                            onPressed: () => _confirmCancelRide(reqid, id),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRideActionButtons(
    String reqid,
    String rideId,
    bool isRequested,
    bool isAccepted,
    bool isConfirmed,
    bool isCancelled,
    bool ridconform,
  ) {
    if (!isRequested || isCancelled) {
      return Text(
        "Waiting for Requests",
        style: TextStyle(color: const Color.fromARGB(255, 255, 245, 245)),
      );
    } else if (ridconform && !isAccepted) {
      return Text(
        "",
        style: TextStyle(color: const Color.fromARGB(255, 255, 245, 245)),
      );
    } else if (!isAccepted) {
      return ElevatedButton(
        onPressed: () => _acceptRide(reqid, rideId),
        child: Text("Accept Ride"),
      );
    } else if (!isConfirmed) {
      return Text(
        "Waiting for Confirmation",
        style: TextStyle(color: Colors.blue),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _startRideOff(context, rideId),
        child: Text("Start Ride"),
      );
    }
  }

  Future<void> _acceptRide(String reqId, String rideId) async {
    try {
      // Fetch the ride request associated with the rideId
      var requestQuery =
          await FirebaseFirestore.instance
              .collection('requested_rides')
              .where('id', isEqualTo: reqId) // Query for the specific rideId
              .get();

      if (requestQuery.docs.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No request found for this ride.',
        );
      }

      // Get the first request (assuming there's only one request per ride)
      var requestDoc = requestQuery.docs.first;
      String requestId = requestDoc.id;

      // Update the ride request to mark it as accepted
      await FirebaseFirestore.instance
          .collection('requested_rides')
          .doc(requestId)
          .update({'isAccepted': true});

      // Update the ride document to mark it as requested and accepted
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'reqid': requestId, // Link the request ID to the ride
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ride request accepted!")));
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Firebase Error: ${e.message}")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _confirmCancelRide(String reqid, String rideId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Colors.orange,
            ),
            content: const Text(
              "Are you sure you want to cancel this ride request?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close dialog
                child: const Text("No", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _cancelRide(
                    reqid,
                    rideId,
                  ); // Call function to cancel ride
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Yes, Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelRide(String reqid, String rideId) async {
    await FirebaseFirestore.instance
        .collection('requested_rides')
        .doc(reqid)
        .update({'isAccepted': false});

    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'reqid': '', // Link the request ID to the ride
    });
    _showCustomPopup(
      icon: Icons.check_circle,
      message: "Ride canceled successfully.",
      iconColor: Colors.red,
    );
  }

  Future<void> _startRideOff(BuildContext context, String rideId) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permission permanently denied!");
        return;
      }
    }

    // ✅ Fetch the current driver's location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng driverLocation = LatLng(position.latitude, position.longitude);
    DocumentSnapshot rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    final String srideId = rideSnapshot['srideId'];
    final String ddriverId = rideSnapshot['userId'];
    final String id = rideSnapshot['id'];
    print("🚀 Ride Session ID: $srideId");
    print("🚀 Ride driver ID: $ddriverId");
    FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'srideId': srideId,
      'isStarted': true,
    });

    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(srideId)
        .update({
          'srideId': srideId,
          'driverLat': driverLocation.latitude,
          'driverLng': driverLocation.longitude,
          'driverId': ddriverId,
          'distanceTraveled': 0.0,
          'rideStatus': "On the way",
          'isCancelled': false,
          'isCompleted': false,
          'isDriverStarted': true,
          'rating': 0,
          'offid': id,
        });
    print("🚖 Ride started: Driver location updated, and srideId set!");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                StartRideScreen(rideId: srideId, currentUserId: ddriverId),
      ),
    );
  }

  /// Fetch Requested Rides

  Widget _buildRequestedRides() {
    if (user == null) return _buildErrorText("Error: User not logged in.");
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection('requested_rides')
              .where('userId', isEqualTo: user!.uid)
              .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildErrorText("No ride requests yet.");
        return _buildRequestedRideList(snapshot.data!.docs);
      },
    );
  }

  /// requestedd ride list
  Widget _buildRequestedRideList(List<QueryDocumentSnapshot> requestedRides) {
    var activeRequests =
        requestedRides.where((ride) {
          var rideData = ride.data() as Map<String, dynamic>?;

          if (rideData == null) return false;

          Timestamp? reachTime =
              rideData.containsKey('reachTime')
                  ? rideData['reachTime'] as Timestamp?
                  : null;

          bool isCompleted = rideData['isCompleted'] ?? false;
          bool isCancelled =
              rideData['isCancelled'] ?? false; // New filter added

          return reachTime != null &&
              reachTime.toDate().isAfter(DateTime.now()) &&
              !isCompleted && // Exclude completed rides
              !isCancelled; // Exclude cancelled ride requests
        }).toList();

    if (activeRequests.isEmpty) {
      return _buildErrorText("No active ride requests.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const BouncingScrollPhysics(), // Allows scrolling within TabBarView
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        var ride = activeRequests[index];
        bool isAccepted = ride['isAccepted'] ?? false;
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('rides')
                  .doc(ride['rideId'])
                  .get(),
          builder: (context, rideSnapshot) {
            if (rideSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!rideSnapshot.hasData || !rideSnapshot.data!.exists) {
              return const SizedBox.shrink(); // Hide if ride doesn't exist
            }
            print("hkj👌👌${isAccepted}");
            var rideData = rideSnapshot.data!.data() as Map<String, dynamic>;
            bool isConfirmed = rideData['isConfirmed'] ?? false;
            bool isCompleted = rideData['isCompleted'] ?? false;
            bool isCancelled =
                rideData['isCancelled'] ?? false; // New filter added
            print("nkfsjdnjk😁😁😁😁${isCompleted}");
            if (isCompleted || isCancelled) {
              return const SizedBox.shrink(); // Hide completed or cancelled rides
            }
            //ride-requested ride
            //rideData-ride
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 5),
              color: Colors.black.withOpacity(0.6),
              child: ListTile(
                leading: const Icon(Icons.directions_bike, color: Colors.blue),
                title: Text(
                  "${ride['departure']} ➝ ${ride['destination']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Start: ${_formatTimeOnly(ride['startTime'])}\n"
                  "End: ${_formatTimeOnly(ride['reachTime'])}",
                  style: const TextStyle(color: Colors.white70),
                ),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRequestedRideActions(
                      ride.id,
                      ride['rideId'],
                      isAccepted,
                      isConfirmed,
                    ),

                    // Cancel Button (Only if ride is NOT confirmed)
                    if (!isConfirmed)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: "Cancel Request",
                        onPressed: () => _confirmCancelRideRequest(ride.id),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ///conform canncel
  void _confirmCancelRideRequest(String requestId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: Colors.orange,
            ),
            content: const Text(
              "Are you sure you want to cancel this ride request?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close dialog
                child: const Text("No", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _cancelRideRequest(
                    requestId,
                  ); // Call function to cancel
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Yes, Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  /// cancel ride request
  Future<void> _cancelRideRequest(String requestId) async {
    final ofride;
    DocumentSnapshot ofrideSnapshot =
        await FirebaseFirestore.instance
            .collection('requested_rides')
            .doc(requestId)
            .get();

    ofride = ofrideSnapshot['rideId'];
    await FirebaseFirestore.instance.collection('rides').doc(ofride).update({
      'reqid': '',
      'isConfirmed': false,
      'srideId': '',
    });
    await FirebaseFirestore.instance
        .collection('requested_rides')
        .doc(requestId)
        .delete();

    _showCustomPopup(
      icon: Icons.check_circle,
      message: "Ride request canceled successfully.",
      iconColor: Colors.red,
    );
  }

  /// Build Requested Ride Action Buttons
  Widget _buildRequestedRideActions(
    String requestId,
    String rideId,
    bool isAccepted,
    bool isConfirmed,
  ) {
    if (isConfirmed && !isAccepted) {
      return Text(
        "Ride is occupied",
        style: TextStyle(color: const Color.fromARGB(255, 255, 245, 245)),
      );
    } else if (!isAccepted) {
      return const Text(
        "Waiting for Acceptance",
        style: TextStyle(color: Colors.grey),
      );
    } else if (!isConfirmed) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: () => _confirmRide(rideId),
        child: const Text("Confirm Ride"),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        onPressed: () => _startRideReq(context, rideId, requestId),
        child: const Text("Start Ride"),
      );
    }
  }

  Future<void> _startRideReq(
    BuildContext context,
    String rideId,
    String requestId,
  ) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permission permanently denied!");
        return;
      }
    }

    // ✅ Fetch the current passenger's location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng passengerLocation = LatLng(position.latitude, position.longitude);

    DocumentSnapshot rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    final String reqId = rideSnapshot['reqid'];
    final String id = rideSnapshot['id'];
    print("🚀 Ride Session ID: $requestId");
    print("🚀 Ride Session ID: $reqId");
    print("🚀 Ride ID: $rideId");
    //print("🚀 Ride Session ID: $srideId");
    DocumentSnapshot reqrideSnapshot =
        await FirebaseFirestore.instance
            .collection('requested_rides')
            .doc(reqId)
            .get();
    final String passenagerId = reqrideSnapshot['userId'];
    final String srideId = reqrideSnapshot['srideId'];
    print("🚀 Passenger ID: $passenagerId");
    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(srideId)
        .update({
          'passengerLat': passengerLocation.latitude,
          'passengerLng': passengerLocation.longitude,
          'passengerId': passenagerId,
          'distanceTraveled': 0.0,
          'rideStatus': "On the way",
          'isCancelled': false,
          'isCompleted': false,
          'ispassengerStarted': true,
          'rid': reqId,
        });

    print("🚖 Ride started: Passenger location updated, and srideId set!");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                StartRideScreen(rideId: srideId, currentUserId: passenagerId),
      ),
    );
  }

  /// Confirm Ride (Updates `isConfirmed` in `rides`)
  Future<void> _confirmRide(String rideId) async {
    String srideId = Uuid().v4(); // Generate a unique srideId

    // Create a StartRideModel instance
    StartRideModel ride = StartRideModel(
      rideId: '',
      driverId: '',
      passengerId: '',
      driverLat: 0.0,
      driverLng: 0.0,
      passengerLat: 0.0,
      passengerLng: 0.0,
      distanceTraveled: 0.0,
      rideStatus: "On the way",
      isCancelled: false,
      ispassengerStarted: false,
      isDriverStarted: true,
      isCompleted: false,
    );

    // Save ride data to Firestore
    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(srideId)
        .set(ride.toFirestore());

    // Update the original ride document
    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'srideId': srideId, // Set new srideId
      'isConfirmed': true, // Mark ride as confirmed
    });
    DocumentSnapshot rideSnapshot =
        await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    final String reqId = rideSnapshot['reqid'];

    await FirebaseFirestore.instance
        .collection('requested_rides')
        .doc(reqId)
        .update({
          'srideId': srideId,
          'isConfirmed': true, // Set new srideId
        });

    print(
      "✅ Ride Confirmed! srideId: $srideId assigned and ride added to Firestore.",
    );
  }

  Widget _buildErrorText(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
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
                    "done",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _formatTimeOnly(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    String period = date.hour >= 12 ? "PM" : "AM";
    int hour =
        date.hour % 12 == 0 ? 12 : date.hour % 12; // Convert to 12-hour format

    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "$hour:${date.minute.toString().padLeft(2, '0')} $period";
  }
}
