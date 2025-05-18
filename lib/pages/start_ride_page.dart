import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/home_screen.dart';

class StartRideScreen extends StatefulWidget {
  final String rideId;
  final String currentUserId;

  StartRideScreen({required this.rideId, required this.currentUserId});

  @override
  _StartRideScreenState createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  bool _isRideStarted = false;
  bool _isRideCompleted = false;
  bool _isStartRideDialogShown = false;
  LatLng? _offeredUserLocation;
  LatLng? _requestedUserLocation;
  double? _distanceBetweenUsers;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isDriver = false;
  String? _otherUserPhoneNumber;
  String? _otherUserName;
  String? _otherUserId;
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _determineUserRole();
  }

  Future<void> _determineUserRole() async {
    final rideDoc =
        await FirebaseFirestore.instance
            .collection('started_rides')
            .doc(widget.rideId)
            .get();

    if (rideDoc.exists) {
      final data = rideDoc.data()!;
      setState(() {
        _isDriver = data['driverId'] == widget.currentUserId;
      });

      // Get the other user's ID

      if (widget.currentUserId == data['passengerId']) {
        _otherUserId = data['driverId'];
      } else if (widget.currentUserId == data['driverId']) {
        _otherUserId = data['passengerId'];
      } else {
        _otherUserId = null;
      }
      // Fetch the other user's details
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_otherUserId)
              .get();

      if (userDoc.exists) {
        setState(() {
          _otherUserPhoneNumber = userDoc['phone'];
          _otherUserName = userDoc['name'];
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission permanently denied!"),
          ),
        );
        return;
      }
    }

    _trackLiveLocations(); // Start listening to Firestore updates
    _startUpdatingLocation(); // Start updating live location for both users
  }

  Timer? _locationUpdateTimer;

  void _startUpdatingLocation() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Determine if the current user is the driver or passenger
        final String userLatKey = _isDriver ? 'driverLat' : 'passengerLat';
        final String userLngKey = _isDriver ? 'driverLng' : 'passengerLng';

        // Update Firestore with the current user's location
        await FirebaseFirestore.instance
            .collection('started_rides')
            .doc(widget.rideId)
            .update({
              userLatKey: position.latitude,
              userLngKey: position.longitude,
            });

        // Update local state
        setState(() {
          if (_isDriver) {
            _offeredUserLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          } else {
            _requestedUserLocation = LatLng(
              position.latitude,
              position.longitude,
            );
          }
        });

        _updateMapMarkers();
      } catch (e) {
        print("Error updating location: $e");
      }
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _trackLiveLocations() {
    FirebaseFirestore.instance
        .collection('started_rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((rideDoc) {
          if (rideDoc.exists) {
            final data = rideDoc.data()!;
            setState(() {
              _requestedUserLocation = LatLng(
                data['passengerLat'] ?? 0.0,
                data['passengerLng'] ?? 0.0,
              );
              _offeredUserLocation = LatLng(
                data['driverLat'] ?? 0.0,
                data['driverLng'] ?? 0.0,
              );
            });
            _calculateDistance();
            _updateMapMarkers();
            if (_haveUsersMet() && !_isStartRideDialogShown) {
              _showStartRideDialog();
              _isStartRideDialogShown = true;
            }
          }
        });
  }

  void _calculateDistance() {
    if (_offeredUserLocation != null && _requestedUserLocation != null) {
      final distance = Geolocator.distanceBetween(
        _offeredUserLocation!.latitude,
        _offeredUserLocation!.longitude,
        _requestedUserLocation!.latitude,
        _requestedUserLocation!.longitude,
      );

      setState(() => _distanceBetweenUsers = distance);
    }
  }

  bool _haveUsersMet() =>
      _distanceBetweenUsers != null && _distanceBetweenUsers! < 100;

  void _updateMapMarkers() {
    _markers.clear();
    if (_offeredUserLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId("offeredUser"),
          position: _offeredUserLocation!,
          infoWindow: InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (_requestedUserLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId("requestedUser"),
          position: _requestedUserLocation!,
          infoWindow: InfoWindow(title: "Requested User"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    if (_mapController != null && _offeredUserLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_offeredUserLocation!),
      );
    }
  }

  void _showStartRideDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Users Met!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Do you want to start the ride or cancel it?"),
                if (_distanceBetweenUsers != null &&
                    _distanceBetweenUsers! < 100 &&
                    _otherUserPhoneNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Text(
                          "${_isDriver ? 'Passenger' : 'Driver'} Contact:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Name: $_otherUserName",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Phone: $_otherUserPhoneNumber",
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.phone, color: Colors.green),
                              onPressed:
                                  () => _makePhoneCall(_otherUserPhoneNumber!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmCancelRide();
                },
                child: Text("Cancel Ride", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startRide();
                },
                child: Text("Start Ride"),
              ),
            ],
          ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch phone call!')));
    }
  }

  Future<void> _confirmCancelRide() async {
    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(widget.rideId)
        .update({'isCancelled': true});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🚫 Ride request has been cancelled.")),
    );
  }

  Future<void> _startRide() async {
    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(widget.rideId)
        .update({'isStarted': true});
    setState(() => _isRideStarted = true);
  }

  Future<void> _completeRide() async {
    await FirebaseFirestore.instance
        .collection('started_rides')
        .doc(widget.rideId)
        .update({'isCompleted': true});
    DocumentSnapshot rideDoc =
        await FirebaseFirestore.instance
            .collection('started_rides')
            .doc(widget.rideId)
            .get();
    String rid = rideDoc['rid'];
    String ofid = rideDoc['offid'];
    print("🙌${widget.rideId}");
    print("🙌${rid}");
    print("🤦‍♂️${ofid}");

    //final String pas = rideDoc['passengerId'];
    await FirebaseFirestore.instance.collection('rides').doc(ofid).update({
      'isCompleted': true,
    });

    await FirebaseFirestore.instance
        .collection('requested_rides')
        .doc(rid)
        .update({'isCompleted': true});
    setState(() => _isRideCompleted = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("🎉 Ride Completed Successfully!")));
    _showRatingDialog();
  }

  void _showRatingDialog() {
    double _rating = 3.0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rate Your Ride'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rate your ride experience',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder:
                      (context, _) => Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) => _rating = rating,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _submitRating(_rating);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  );
                },
                child: Text('Submit'),
              ),
            ],
          ),
    );
  }

  Future<void> _submitRating(double rating) async {
    try {
      final rideRef = FirebaseFirestore.instance
          .collection('started_rides')
          .doc(widget.rideId);
      final rideSnapshot = await rideRef.get();

      if (rideSnapshot.exists) {
        final passengerId = rideSnapshot['passengerId'];
        final driverId = rideSnapshot['driverId'];
        await rideRef.update({'rating': rating});
        if (widget.currentUserId == passengerId &&
            rideSnapshot['rating'] == 0) {
          await _updateUserRating(driverId, rating);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rating submitted successfully!')),
          );
        } else if (widget.currentUserId == driverId &&
            rideSnapshot['rating'] == 0) {
          await _updateUserRating(passengerId, rating);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rating submitted successfully!')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ride not found!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting rating: $e')));
    }
  }

  Future<void> _updateUserRating(String Id, double newRating) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(Id);
    final userSnapshot = await userRef.get();

    final currentTotalRating = (userSnapshot['totalRatings'] ?? 0).toDouble();
    final currentNumberOfRatings =
        (userSnapshot['numberOfRatings'] ?? 0).toInt();

    final updatedTotalRating = currentTotalRating + newRating;
    final updatedNumberOfRatings = currentNumberOfRatings + 1;
    final updatedAverageRating = updatedTotalRating / updatedNumberOfRatings;

    await userRef.update({
      'totalRatings': updatedTotalRating,
      'numberOfRatings': updatedNumberOfRatings,
      'averageRating': updatedAverageRating,
    });
  }

  Future<void> _refreshLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _offeredUserLocation = LatLng(position.latitude, position.longitude);
    });
    _updateMapMarkers();
  }

  Future<void> _makeEmergencyCall() async {
    const phoneNumber = 'tel:7034592461'; // Replace with your emergency number
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch emergency call!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Start Ride")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_distanceBetweenUsers != null)
                        Text(
                          "📍 Distance: ${_distanceBetweenUsers! < 1000 ? '${_distanceBetweenUsers!.toStringAsFixed(1)} m' : '${(_distanceBetweenUsers! / 1000).toStringAsFixed(2)} km'}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      if (_distanceBetweenUsers != null &&
                          _distanceBetweenUsers! < 100 &&
                          _otherUserPhoneNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              Text(
                                "${_isDriver ? 'Passenger' : 'Driver'} Contact:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text("Name: $_otherUserName"),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Phone: $_otherUserPhoneNumber"),
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _makePhoneCall(
                                          _otherUserPhoneNumber!,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_isRideCompleted)
                        Text(
                          "✅ Ride Completed!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      else if (_isRideStarted)
                        ElevatedButton.icon(
                          onPressed: _completeRide,
                          icon: Icon(Icons.done, size: 20),
                          label: Text("Complete Ride"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        )
                      else
                        Text("Waiting for users to meet..."),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _refreshLocation,
              child: Icon(Icons.refresh),
              mini: true,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _makeEmergencyCall,
            child: Icon(Icons.emergency),
            backgroundColor: Colors.red,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _refreshLocation,
            child: Icon(Icons.refresh),
            backgroundColor: Colors.blue,
          ),
          SizedBox(height: 46),
        ],
      ),
    );
  }
}
