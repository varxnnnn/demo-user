import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../models/trip.dart';
import '../../models/driver.dart';
import '../../models/vehicle_capacity.dart';
import 'payment_screen.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../../services/ride_completion_service.dart';
import '../../models/ride_completion.dart';

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
  GoogleMapController? _mapController;
  Set<Marker> _markers = <Marker>{};
  late StreamSubscription<DocumentSnapshot> _tripSub;
  String? _driverLocationLat;
  String? _driverLocationLng;
  String? _driverCurrentStatus;
  String? _driverName;
  String? _driverId;
  Trip? _updatedTrip;
  Driver? _driverData;
  bool _isNearDestination = false;

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
      final driverId = _driverId ?? widget.trip.driverId;
      if (driverId == null) return;
      
      _driverData = await Driver.fromIdWithVehicle(driverId, FirebaseFirestore.instance);
      if (mounted) setState(() {});
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;
    
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position currentLocation = await Geolocator.getCurrentPosition();
        
        double distanceToDestination = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          widget.trip.dropoffLat,
          widget.trip.dropoffLng,
        );

        if (distanceToDestination < 200 && !_isNearDestination) {
          setState(() {
            _isNearDestination = true;
          });
        }

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
        
        _updateDriverMarker(currentLocation.latitude, currentLocation.longitude);
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(currentLocation.latitude, currentLocation.longitude),
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
    return 12742 * asin(sqrt(a)) * 1000;
  }

  void _startVerificationListener() {
    _tripSub = FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data['driverId'] != null) {
        setState(() {
          _driverName = data['driverName'];
          _driverId = data['driverId'];
          _driverCurrentStatus = data['status'];
          
          _updatedTrip = Trip.fromJson(data, id: doc.id);
        });
      }

      if (data['driverLocation'] != null) {
        final driverLoc = data['driverLocation'];
        if (driverLoc['latitude'] != null && driverLoc['longitude'] != null) {
          setState(() {
            _driverLocationLat = driverLoc['latitude'].toString();
            _driverLocationLng = driverLoc['longitude'].toString();
          });
          _updateDriverMarker(driverLoc['latitude'], driverLoc['longitude']);
        }
      }
    });
  }

  Future<void> _completeRide(String paymentMethod) async {
    try {
      final dId = _driverId ?? widget.trip.driverId;
      if (dId == null) return;

      final rideCompletionService = RideCompletionService();
      
      final completionDetails = RideCompletionDetails(
        tripId: widget.trip.id,
        driverId: dId,
        userId: widget.trip.userId,
        baseFare: widget.trip.fare,
        additionalCharges: 0,
        discount: 0,
        totalFare: widget.trip.fare,
        paymentMethod: paymentMethod,
        paymentReceived: true,
        completedAt: DateTime.now(),
      );

      // Use the unified service to complete ride and restore capacity
      await rideCompletionService.completeRide(
        tripId: widget.trip.id,
        completionDetails: completionDetails,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error completing ride: $e');
    }
  }

  void _updateDriverMarker(double lat, double lng) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Driver Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDriverInfoCard(),
                  const SizedBox(height: 16),
                  _buildRouteInfoCard(),
                  const SizedBox(height: 16),
                  if (_driverData?.vehicleCapacity != null) ...[
                    _buildCapacityCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildMapCard(),
                ],
              ),
            ),
          ),
          if (_isNearDestination)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SlideAction(
                text: 'Slide to Complete Ride',
                onSubmit: () async {
                  final paymentMethod = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(amount: widget.trip.fare),
                    ),
                  );

                  if (paymentMethod != null) {
                    await _completeRide(paymentMethod);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Trip #${widget.trip.id.substring(0, 6)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _driverName ?? _updatedTrip?.driverName ?? widget.trip.driverName ?? 'Driver not assigned',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName ?? _updatedTrip?.driverName ?? widget.trip.driverName ?? 'Driver not assigned',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('4.8 • Driver ID: ${_driverId ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.location_on, 'Pickup', widget.trip.pickupLocation, Colors.green),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.location_on, 'Dropoff', widget.trip.dropoffLocation, Colors.red),
            const SizedBox(height: 16),
            _buildInfoRow('Fare', '₹${widget.trip.fare.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCard() {
    final cap = _driverData!.vehicleCapacity!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Capacity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCapacityIndicator('Seats', cap.availableSeats, cap.totalSeats, Icons.airline_seat_recline_normal, Colors.blue),
                _buildCapacityIndicator('Cargo', cap.availableCargoKg.toInt(), cap.totalCargoKg.toInt(), Icons.inventory, Colors.green, unit: 'kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Live Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(widget.trip.pickupLat, widget.trip.pickupLng), zoom: 14.0),
                onMapCreated: (c) => _mapController = c,
                markers: _markers,
                myLocationEnabled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String title, String location, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityIndicator(String title, int current, int total, IconData icon, Color color, {String unit = ''}) {
    double percentage = total > 0 ? (current / total) : 0;
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('$current/$total $unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
