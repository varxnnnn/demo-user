import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverDashboardScreen extends StatefulWidget {
  static const String id = '/driver-dashboard';

  @override
  _DriverDashboardScreenState createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  String _currentStatus = 'offline'; // offline, online, driving
  Stream<QuerySnapshot>? _activeRidesStream;

  @override
  void initState() {
    super.initState();
    _setupActiveRidesStream();
  }

  void _setupActiveRidesStream() {
    _activeRidesStream = FirebaseFirestore.instance
        .collection('rides')
        .where('status', whereIn: ['requested', 'confirmed'])
        .snapshots();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateDriverLocationOnMap();
  }

  void _updateDriverLocationOnMap() async {
    // In a real app, you would get the driver's current location
    // For now, using a sample location
    final currentPos = const LatLng(40.7128, -74.0060); // New York as example
    
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: currentPos,
          infoWindow: const InfoWindow(title: 'You (Driver)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
      
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('driver-radius'),
          center: currentPos,
          radius: 5000, // 5km radius
          fillColor: Colors.green.withOpacity(0.2),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
      );
    });
  }

  void _toggleDriverStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final newStatus = _currentStatus == 'online' ? 'offline' : 'online';
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: _currentStatus == 'online' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _acceptRide(String rideId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'driverId': user.uid,
        'status': 'confirmed',
        'driverAcceptedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({'currentRideId': rideId, 'status': 'driving'});

      setState(() {
        _currentStatus = 'driving';
      });

      // Navigate to ride details screen
      Navigator.pushNamed(context, '/driver-ride-details', arguments: rideId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'profile') {
                Navigator.pushNamed(context, '/driver-profile');
              } else if (choice == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (BuildContext context) {
              return {'profile', 'logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice == 'profile' ? 'Profile' : 'Logout'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentStatus == 'online' 
                  ? Colors.green[100] 
                  : _currentStatus == 'driving' 
                      ? Colors.blue[100] 
                      : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentStatus == 'online' 
                    ? Colors.green 
                    : _currentStatus == 'driving' 
                        ? Colors.blue 
                        : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_currentStatus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _currentStatus == 'online' 
                            ? Colors.green 
                            : _currentStatus == 'driving' 
                                ? Colors.blue 
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentStatus == 'online'
                          ? 'Looking for rides...'
                          : _currentStatus == 'driving'
                              ? 'Currently on a ride'
                              : 'Offline - not accepting rides',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Switch(
                  value: _currentStatus != 'offline',
                  onChanged: (_) => _toggleDriverStatus(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          
          // Map View
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(40.7128, -74.0060),
                  zoom: 12,
                ),
                markers: _markers,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Active Rides Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _activeRidesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active ride requests nearby',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final ride = snapshot.data!.docs[index];
                    final rideData = ride.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ride #${ride.id.substring(0, 5)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  rideData['bookingType'] == 'person' ? '👤 Person' : '📦 Cargo',
                                  style: TextStyle(
                                    color: rideData['bookingType'] == 'person' 
                                        ? Colors.blue 
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('From:', rideData['pickupLocation']),
                            _buildInfoRow('To:', rideData['destination']),
                            _buildInfoRow('Distance:', rideData['distance'] ?? 'N/A'),
                            _buildInfoRow('Fare:', rideData['fareEstimate'] ?? 'N/A'),
                            const SizedBox(height: 12),
                            if (_currentStatus == 'online')
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () => _acceptRide(ride.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('ACCEPT RIDE'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}