import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offered_ride_Model.dart';

class OfferRideScreen extends StatefulWidget {
  @override
  _OfferRideScreenState createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  Timestamp? startTime;
  Timestamp? endTime;
  String? selectedGender;
  final List<String> genderOptions = ["Male", "Female", "Any"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offer a Ride"),
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
          Container(color: Colors.black.withOpacity(0.6)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 100), // Space for app bar
                  // Departure Field
                  TextField(
                    controller: departureController,
                    style: const TextStyle(
                      color: Colors.white,
                    ), // Set text color to white
                    decoration: InputDecoration(
                      labelText: "Departure",
                      labelStyle: const TextStyle(
                        color: Colors.white,
                      ), // Set label color
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  // Destination Field
                  TextField(
                    controller: destinationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Destination",
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Start Time Picker
                  ListTile(
                    title: Text(
                      "Pick Start Time",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle:
                        startTime != null
                            ? Text(
                              _formatTimestamp(startTime!),
                              style: TextStyle(color: Colors.white70),
                            )
                            : Text(
                              "No time selected",
                              style: TextStyle(color: Colors.white70),
                            ),
                    trailing: Icon(Icons.access_time, color: Colors.white),
                    onTap: () => _pickStartTime(context),
                  ),
                  // End Time Picker
                  ListTile(
                    title: Text(
                      "Pick End Time",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle:
                        endTime != null
                            ? Text(
                              _formatTimestamp(endTime!),
                              style: TextStyle(color: Colors.white70),
                            )
                            : Text(
                              "No time selected",
                              style: TextStyle(color: Colors.white70),
                            ),
                    trailing: Icon(Icons.access_time, color: Colors.white),
                    onTap: () => _pickEndTime(context),
                  ),
                  const SizedBox(height: 16),
                  // Gender Preference Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    hint: Text(
                      "Select Gender Preference",
                      style: TextStyle(color: Colors.white), // Hint text color
                    ),
                    items:
                        genderOptions.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Container(
                              color:
                                  Colors
                                      .black, // Background color for dropdown items
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: Colors.white,
                                ), // Text color for dropdown items
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue!;
                      });
                    },
                    dropdownColor: Colors.black.withOpacity(
                      0.3,
                    ), // Background color for the dropdown menu
                    decoration: InputDecoration(
                      labelText: "Gender Preference",
                      filled: true,
                      labelStyle: const TextStyle(
                        color: Colors.white,
                      ), // Label text color
                      fillColor: Colors.black.withOpacity(
                        0.4,
                      ), // Background color of the input field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Offer Ride Button
                  ElevatedButton(
                    onPressed: _offerRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(165, 101, 101, 0.8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Offer Ride",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const Divider(color: Colors.white70),
                  const SizedBox(height: 10),
                  // Your Offered Rides Section
                  Text(
                    "Your Offered Rides",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildOfferedRides(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferedRides() {
    if (user == null) return Center(child: Text("Error: User not logged in."));

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection('rides')
              .where('userId', isEqualTo: user!.uid)
              .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "No rides offered yet.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        var rides = snapshot.data!.docs;

        // ✅ Sorting in-memory (newest first)
        rides.sort((a, b) {
          Timestamp aTime = a['createdAt'] as Timestamp;
          Timestamp bTime = b['createdAt'] as Timestamp;
          return bTime.compareTo(aTime); // 🔥 Sort descending (newest first)
        });

        return SizedBox(
          height: 250,
          child: ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              var ride = rides[index];
              var rideData = ride.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                color: Colors.black.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ride Route
                      Text(
                        "${rideData['departure']} ➝ ${rideData['destination']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Ride Timing
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.orangeAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Start: ${_formatTimestamp(rideData['startTime'])}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_off,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "End: ${_formatTimestamp(rideData['reachTime'])}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Gender Preference
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.lightBlueAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Gender: ${rideData['genderPreference'].toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _offerRide() async {
    if (user == null ||
        startTime == null ||
        endTime == null ||
        selectedGender == null ||
        departureController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      _showCustomPopup(
        icon: Icons.error,
        message: "Please fill all fields correctly.",
        iconColor: Colors.red,
      );
      return;
    }

    String departure = departureController.text.trim();
    String destination = destinationController.text.trim();

    // ✅ Check for duplicate ride
    QuerySnapshot existingRides =
        await FirebaseFirestore.instance
            .collection('rides')
            .where('userId', isEqualTo: user!.uid)
            .where('departure', isEqualTo: departure)
            .where('destination', isEqualTo: destination)
            .where('startTime', isEqualTo: startTime)
            .get();

    if (existingRides.docs.isNotEmpty) {
      _showCustomPopup(
        icon: Icons.warning_amber_rounded,
        message: "You have already offered this ride!",
        iconColor: Colors.orange,
      );
      return;
    }

    // ✅ Proceed if no duplicate is found
    Timestamp createdAt = Timestamp.now();
    OfferedRide ride = OfferedRide(
      id: '',
      userId: user!.uid,
      departure: departure,
      destination: destination,
      startTime: startTime!,
      reachTime: endTime!,
      genderPreference: selectedGender!,
      createdAt: createdAt,
    );

    var docRef = await FirebaseFirestore.instance
        .collection('rides')
        .add(ride.toMap());
    await FirebaseFirestore.instance.collection('rides').doc(docRef.id).update({
      'id': docRef.id,
    });

    _showCustomPopup(
      icon: Icons.check_circle,
      message: "Ride Offered Successfully!",
      iconColor: Colors.green,
    );
    departureController.clear();
    destinationController.clear();
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

  Future<void> _pickStartTime(BuildContext context) async {
    DateTime? pickedDate = await _pickDateTime(context);
    if (pickedDate != null) {
      setState(() {
        startTime = Timestamp.fromDate(pickedDate);
      });
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    DateTime? pickedDate = await _pickDateTime(context);
    if (pickedDate != null) {
      if (startTime != null && pickedDate.isBefore(startTime!.toDate())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("End time must be after start time!")),
        );
        return;
      }
      setState(() {
        endTime = Timestamp.fromDate(pickedDate);
      });
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    String period = date.hour >= 12 ? "PM" : "AM";
    int hour =
        date.hour % 12 == 0 ? 12 : date.hour % 12; // Convert to 12-hour format

    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "$hour:${date.minute.toString().padLeft(2, '0')} $period";
  }
}
