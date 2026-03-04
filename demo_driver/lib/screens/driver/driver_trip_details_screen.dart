import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/trip.dart';
import '../../models/driver.dart';
import '../../models/vehicle_capacity.dart';
import 'dart:math';

class DriverTripDetailsScreen extends StatefulWidget {
  static const String id = 'driver_trip_details';
  final Trip trip;

  const DriverTripDetailsScreen({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<DriverTripDetailsScreen> createState() => _DriverTripDetailsScreenState();
}

class _DriverTripDetailsScreenState extends State<DriverTripDetailsScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = <Marker>{};
  late StreamSubscription<DocumentSnapshot> _tripSub;
  String? _driverLocationLat;
  String? _driverLocationLng;
  String? _driverCurrentStatus;
  String? _driverName;
  String? _driverId;
  Trip? _updatedTrip;
  Driver? _driverData;
  bool _isWithinPickupRadius = false;
  bool _showCodeEntryDialog = false;

  Timer? _locationUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _startVerificationListener();
    _addInitialMarkers();
    _startLocationUpdates();
  }

  void _loadDriverData() async {
    try {
      // Get current driver ID from provider or auth
      final driverId = _driverId ?? widget.trip.driverId;
      if (driverId == null) return;
      
      _driverData = await Driver.fromIdWithVehicle(driverId, FirebaseFirestore.instance);
      print('Driver data loaded: ${_driverData?.name}');
    } catch (e) {
      print('Error loading driver data: $e');
    }
  }
  
  void _addInitialMarkers() {
    setState(() {
      _markers = <Marker>{
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.trip.pickupLat,
            widget.trip.pickupLng,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.trip.pickupLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            widget.trip.dropoffLat,
            widget.trip.dropoffLng,
          ),
          infoWindow: InfoWindow(
            title: 'Dropoff Location',
            snippet: widget.trip.dropoffLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }
  
  void _startLocationUpdates() async {
    // Request location permission first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }
    
    // Update driver location every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Get current location
        Position currentLocation = await Geolocator.getCurrentPosition();
        
        // Check if driver is within pickup radius (100m)
        double distanceToPickup = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          widget.trip.pickupLat,
          widget.trip.pickupLng,
        );
        
        bool withinRadius = distanceToPickup <= 100; // 100 meters
        
        if (withinRadius && !_isWithinPickupRadius) {
          setState(() {
            _isWithinPickupRadius = true;
            _showCodeEntryDialog = true;
          });
          
          // Show code entry dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_showCodeEntryDialog) {
              _showCodeEntryDialog = false;
              _showVerificationCodeDialog();
            }
          });
        } else if (!withinRadius && _isWithinPickupRadius) {
          setState(() {
            _isWithinPickupRadius = false;
          });
        }
        
        // Update driver location in Firestore
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.trip.id)
            .update({
          'driverLocation': {
            'latitude': currentLocation.latitude,
            'longitude': currentLocation.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Also update in the rideRequests collection for consistency
        await FirebaseFirestore.instance
            .collection('rideRequests')
            .doc(widget.trip.id)
            .update({
          'driverLocation': {
            'latitude': currentLocation.latitude,
            'longitude': currentLocation.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update local driver marker
        _updateDriverMarker(currentLocation.latitude, currentLocation.longitude);
        
        // Center map on driver's current location
        if (_mapController != null) {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentLocation.latitude, currentLocation.longitude),
              16.0,
            ),
          );
        }
      } catch (e) {
        print('Error updating driver location: $e');
      }
    });
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void _startVerificationListener() {
    _tripSub = FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      // Update driver information if available
      if (data['driverId'] != null) {
        setState(() {
          // We can't modify the final trip object, so we'll update UI state separately
          if (data['driverName'] != null) {
            // Store the driver name in local state
            _driverName = data['driverName'];
          }

          if (data['driverId'] != null) {
            _driverId = data['driverId'];
          }

          // Create an updated trip object with new driver info
          _updatedTrip = Trip(
            id: widget.trip.id,
            userId: widget.trip.userId,
            userName: widget.trip.userName,
            pickupLocation: widget.trip.pickupLocation,
            dropoffLocation: widget.trip.dropoffLocation,
            pickupLat: widget.trip.pickupLat,
            pickupLng: widget.trip.pickupLng,
            dropoffLat: widget.trip.dropoffLat,
            dropoffLng: widget.trip.dropoffLng,
            fare: widget.trip.fare,
            status: widget.trip.status,
            createdAt: widget.trip.createdAt,
            driverId: data['driverId'] ?? widget.trip.driverId,
            driverName: data['driverName'] ?? widget.trip.driverName,
            acceptedAt: widget.trip.acceptedAt,
            completedAt: widget.trip.completedAt,
          );
        });
      }

      // Update driver location if available
      if (data['driverLocation'] != null) {
        final driverLoc = data['driverLocation'];
        if (driverLoc['latitude'] != null && driverLoc['longitude'] != null) {
          setState(() {
            _driverLocationLat = driverLoc['latitude'].toString();
            _driverLocationLng = driverLoc['longitude'].toString();
          });

          // Update driver marker on map
          _updateDriverMarker(driverLoc['latitude'], driverLoc['longitude']);
        }
      }

      // Update driver status if available
      if (data['status'] != null) {
        setState(() {
          _driverCurrentStatus = data['status'];
        });
      }

      // Check for verification code
      final verification = data['verification'];
      if (verification != null && verification['code'] != null) {
        // Don't navigate to code screen for driver, as they shouldn't enter codes
      }
    });
  }

  void _showVerificationCodeDialog() {
    String enteredCode = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Verification Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You have arrived at the pickup location. Please enter the verification code provided by the passenger to start the ride.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 3),
                    onChanged: (value) {
                      enteredCode = value;
                    },
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  if (_driverData?.vehicleCapacity != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Capacity:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Seats: ${_driverData!.vehicleCapacity!.availableSeats}/${_driverData!.vehicleCapacity!.totalSeats}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Cargo: ${_driverData!.vehicleCapacity!.availableCargoKg}/${_driverData!.vehicleCapacity!.totalCargoKg} kg',
                                style: const TextStyle(fontSize: 12),
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
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: enteredCode.isEmpty
                      ? null
                      : () async {
                          // Verify the code
                          try {
                            final tripDoc = await FirebaseFirestore.instance
                                .collection('trips')
                                .doc(widget.trip.id)
                                .get();
                            
                            if (tripDoc.exists) {
                              final data = tripDoc.data();
                              final verification = data?['verification'];
                              
                              if (verification != null && 
                                  verification['code'] == enteredCode) {
                                // Code is correct, start the ride
                                await _startRide();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ride started successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid verification code'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Start Ride'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _startRide() async {
    try {
      // Update trip status to in_progress
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update rideRequests collection
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.trip.id)
          .update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update vehicle capacity if available
      if (_driverData?.vehicleCapacity != null) {
        // For simplicity, we'll reduce available seats by 1 (assuming passenger)
        // In a real app, this would be more sophisticated based on trip type
        int newAvailableSeats = max(0, _driverData!.vehicleCapacity!.availableSeats - 1);
        
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_driverData!.id)
            .update({
          'vehicleCapacity.availableSeats': newAvailableSeats,
          'vehicleCapacity.availableCargoKg': _driverData!.vehicleCapacity!.availableCargoKg,
        });
      }
      
      setState(() {
        _driverCurrentStatus = 'in_progress';
      });
      
      print('Ride started successfully');
    } catch (e) {
      print('Error starting ride: $e');
      rethrow;
    }
  }
  
  void _updateDriverMarker(double lat, double lng) {
    setState(() {
      _markers = <Marker>{
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.trip.pickupLat,
            widget.trip.pickupLng,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.trip.pickupLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            widget.trip.dropoffLat,
            widget.trip.dropoffLng,
          ),
          infoWindow: InfoWindow(
            title: 'Dropoff Location',
            snippet: widget.trip.dropoffLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(
            title: 'Driver Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }



  @override
  void dispose() {
    _tripSub.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Status
              Card(
                color: Colors.blueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _driverCurrentStatus?.toUpperCase() ?? widget.trip.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Trip #${widget.trip.id.substring(0, 6)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _driverName ?? _updatedTrip?.driverName ?? widget.trip.driverName ?? 'Driver not assigned',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Driver Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driverName ?? _updatedTrip?.driverName ?? widget.trip.driverName ?? 'Driver not assigned',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.8 • Driver ID: ${_driverId ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Route Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationRow(
                        icon: Icons.location_on,
                        title: 'Pickup',
                        location: widget.trip.pickupLocation,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationRow(
                        icon: Icons.location_on,
                        title: 'Dropoff',
                        location: widget.trip.dropoffLocation,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Fare', '₹${widget.trip.fare.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Vehicle Capacity Information
              if (_driverData?.vehicleCapacity != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Capacity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCapacityIndicator(
                              'Seats',
                              _driverData!.vehicleCapacity!.availableSeats,
                              _driverData!.vehicleCapacity!.totalSeats,
                              Icons.airline_seat_recline_normal,
                              Colors.blue,
                            ),
                            _buildCapacityIndicator(
                              'Cargo',
                              _driverData!.vehicleCapacity!.availableCargoKg,
                              _driverData!.vehicleCapacity!.totalCargoKg,
                              Icons.inventory,
                              Colors.green,
                              unit: 'kg',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              
              // Manual Code Entry Button
              if (_isWithinPickupRadius && _driverCurrentStatus == 'accepted')
                Card(
                  color: Colors.green,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "You've reached the pickup location. Enter verification code to start the ride.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showVerificationCodeDialog,
                          child: const Text(
                            'Enter Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Map View
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Live Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        child: GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.trip.pickupLat, widget.trip.pickupLng),
                            zoom: 14.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String location,
    Color color = Colors.blue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityIndicator(
    String title,
    int current,
    int total,
    IconData icon,
    Color color, {
    String unit = '',
  }) {
    double percentage = total > 0 ? (current / total) * 100 : 0;
    
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current/$total $unit',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(0)}% free',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}