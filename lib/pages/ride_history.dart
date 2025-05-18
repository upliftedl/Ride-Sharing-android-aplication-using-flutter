import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideHistoryPage extends StatefulWidget {
  @override
  _RideHistoryPageState createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get user => _auth.currentUser;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ Extends body behind AppBar
      appBar: AppBar(
        title: Text("Ride History"),
        backgroundColor: Colors.transparent, // ✅ Transparent AppBar
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white
                .withOpacity(0.1), // ✅ Slight visibility for readability
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.directions_car), text: "Offered Rides"),
                Tab(icon: Icon(Icons.directions_walk), text: "Requested Rides"),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ✅ Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage("assets/bg.png"), // 🔥 Use your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ✅ Semi-transparent overlay for better visibility
          Container(color: Colors.black.withOpacity(0.3)),

          // ✅ Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  top: kToolbarHeight + 20), // 🔥 Adjust spacing below AppBar
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOfferedRides(),
                  _buildRequestedRides(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Offered Rides (Completed)
  Widget _buildOfferedRides() {
    if (user == null) return _buildErrorText("User not logged in.");
    return StreamBuilder(
      stream: _firestore
          .collection('rides')
          .where('userId', isEqualTo: user!.uid)
          .where('isCompleted', isEqualTo: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildErrorText("No completed offered rides.");
        }
        return _buildRideList(snapshot.data!.docs);
      },
    );
  }

  /// ✅ Requested Rides (Completed)
  Widget _buildRequestedRides() {
    if (user == null) return _buildErrorText("User not logged in.");
    return StreamBuilder(
      stream: _firestore
          .collection('requested_rides')
          .where('userId', isEqualTo: user!.uid)
          .where('isCompleted', isEqualTo: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildErrorText("No completed requested rides.");
        }
        return _buildRequestedRideList(snapshot.data!.docs);
      },
    );
  }

  /// ✅ ListView for Offered Rides
  Widget _buildRideList(List<QueryDocumentSnapshot> rides) {
    return ListView.separated(
      padding: EdgeInsets.all(12),
      itemCount: rides.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        var ride = rides[index].data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 16), // ✅ More spacing
          color: Colors.black.withOpacity(0.6), // ✅ Darker for better contrast
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5, // ✅ More shadow for depth
          child: Padding(
            padding: const EdgeInsets.all(16.0), // ✅ More internal padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🚗 Ride Route (Bold & Highlighted)
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: Colors.green, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${ride['departure']} ➝ ${ride['destination']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis, // ✅ Prevents overflow
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // ✅ Increased spacing

                // 🕒 Ride Timing (Start Time)
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Start: ${_formatDateTime(ride['startTime'])}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // ✅ Increased spacing

                // ⏳ Ride Timing (End Time)
                Row(
                  children: [
                    const Icon(Icons.timer_off,
                        color: Colors.redAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "End: ${_formatDateTime(ride['reachTime'])}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ✅ Status (Completed)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Status: Completed",
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ ListView for Requested Rides
  Widget _buildRequestedRideList(List<QueryDocumentSnapshot> requestedRides) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRequestedRideDetails(requestedRides),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildErrorText("No completed requested rides.");
        }

        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            var rideData = snapshot.data![index];

            return Card(
              margin: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16), // ✅ More spacing
              color:
                  Colors.black.withOpacity(0.6), // ✅ Darker for better contrast
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5, // ✅ More shadow for depth
              child: Padding(
                padding: const EdgeInsets.all(16.0), // ✅ More internal padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚗 Ride Route (Bold & Highlighted)
                    Row(
                      children: [
                        const Icon(Icons.directions_walk,
                            color: Colors.blue, size: 22), // ✅ Bigger icon
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${rideData['departure']} ➝ ${rideData['destination']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // ✅ Prevent text overflow
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // ✅ Increased spacing

                    // 🕒 Ride Timing (Start Time)
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Start: ${_formatDateTime(rideData['startTime'])}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // ✅ Increased spacing

                    // ⏳ Ride Timing (End Time)
                    Row(
                      children: [
                        const Icon(Icons.timer_off,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "End: ${_formatDateTime(rideData['reachTime'])}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ✅ Ride Status
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Status: Completed",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
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

  /// ✅ Fetch ride details for requested rides
  Future<List<Map<String, dynamic>>> _fetchRequestedRideDetails(
      List<QueryDocumentSnapshot> requestedRides) async {
    List<Map<String, dynamic>> rideDetails = [];
    for (var request in requestedRides) {
      var rideId = request['rideId'];
      var rideSnapshot = await _firestore.collection('rides').doc(rideId).get();

      if (rideSnapshot.exists) {
        var rideData = rideSnapshot.data() as Map<String, dynamic>;
        rideDetails.add(rideData);
      }
    }
    return rideDetails;
  }

  /// ✅ Error Message Widget
  Widget _buildErrorText(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child:
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  /// ✅ Helper Function: Format Timestamp
  String _formatDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "Unknown";
  }
}
