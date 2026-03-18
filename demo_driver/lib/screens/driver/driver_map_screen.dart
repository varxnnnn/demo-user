import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../services/location_tracking_service.dart';
import '../../services/geofence_verification_service.dart';
import 'verification_entry_screen.dart';
import 'ride_completion_screen.dart';
import '../../services/auth_service.dart';

class DriverMapScreen extends StatefulWidget {
  static const String id = 'driver_map';
  final Trip trip;

  const DriverMapScreen({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final LocationTrackingService _locationTrackingService =
      LocationTrackingService();
  final GeofenceVerificationService _geofenceService = GeofenceVerificationService();

  double? _distanceToUser;
  int? _etaMinutes;
  bool _isTracking = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationTracking();
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    if (_isTracking) {
      _locationTrackingService.stopDriverLocationTracking();
    }
    try {
      _geofenceService.dispose();
    } catch (e) {
      // ignore
    }
    super.dispose();
  }

  void _initializeMap() {
    // Add pickup and dropoff points from trip coordinates immediately
    _markers.clear();
    _addMarker(
      markerId: 'pickup',
      position: LatLng(widget.trip.pickupLat, widget.trip.pickupLng),
      title: 'Pickup',
      snippet: widget.trip.pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    _addMarker(
      markerId: 'dropoff',
      position: LatLng(widget.trip.dropoffLat, widget.trip.dropoffLng),
      title: 'Dropoff',
      snippet: widget.trip.dropoffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.trip.pickupLat, widget.trip.pickupLng),
          LatLng(widget.trip.dropoffLat, widget.trip.dropoffLng),
        ],
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void _startLocationTracking() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;

    if (driverId != null && widget.trip.id.isNotEmpty) {
      _locationTrackingService
          .startDriverLocationTracking(driverId, widget.trip.id)
          .then((_) {
        setState(() {
          _isTracking = true;
        });
        // Start geofence monitoring to auto-generate verification code
        try {
          _geofenceService.monitorTrip(widget.trip.id);
        } catch (e) {
          print('Error starting geofence monitor: $e');
        }
      });
    }
  }

  void _addMarker({
    required String markerId,
    required LatLng position,
    required String title,
    required String snippet,
    BitmapDescriptor? icon,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        icon: icon ?? BitmapDescriptor.defaultMarker,
      ),
    );
  }

  void _updateDriverLocation(double lat, double lng) {
    // Update or add driver location marker
    _markers.removeWhere((marker) => marker.markerId.value == 'driver_current');

    _addMarker(
      markerId: 'driver_current',
      position: LatLng(lat, lng),
      title: 'Your Location',
      snippet: 'Current Position',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {});

    // Update distance and ETA
    _updateDistanceAndETA(lat, lng);

    // Animate camera to show driver location
    if (_mapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  void _updateDistanceAndETA(double driverLat, double driverLng) {
    // Distance and ETA calculation would require pickup location coordinates
    // For now, showing placeholder values
    final distance = 0.0;

    const eta = 0;

    setState(() {
      _distanceToUser = distance;
      _etaMinutes = eta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigate to Pickup'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapReady = true;
              _initializeMap();
              if (widget.trip.pickupLat != 0 && widget.trip.pickupLng != 0) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                        math.min(widget.trip.pickupLat, widget.trip.dropoffLat),
                        math.min(widget.trip.pickupLng, widget.trip.dropoffLng),
                      ),
                      northeast: LatLng(
                        math.max(widget.trip.pickupLat, widget.trip.dropoffLat),
                        math.max(widget.trip.pickupLng, widget.trip.dropoffLng),
                      ),
                    ),
                    80,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.trip.pickupLat == 0 ? 0 : widget.trip.pickupLat,
                  widget.trip.pickupLng == 0 ? 0 : widget.trip.pickupLng),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
          // Real-time location stream
          StreamBuilder<Map<String, dynamic>?>(
            stream: _locationTrackingService.getDriverLocationStream(
              widget.trip.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final location = snapshot.data!;
                if (location['latitude'] != null &&
                    location['longitude'] != null) {
                  _updateDriverLocation(
                    location['latitude'],
                    location['longitude'],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        icon: Icons.directions,
                        label: 'Distance',
                        value: _distanceToUser != null
                            ? '${_distanceToUser!.toStringAsFixed(1)} km'
                            : '--',
                        valueColor: Colors.blue,
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildInfoChip(
                        icon: Icons.timer,
                        label: 'ETA',
                        value: _etaMinutes != null ? '$_etaMinutes min' : '--',
                        valueColor: Colors.orange,
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildInfoChip(
                        icon: Icons.location_on,
                        label: 'Status',
                        value: 'En Route',
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            widget.trip.userName.isNotEmpty
                                ? widget.trip.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.trip.userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.5',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {
                            // TODO: Implement call functionality
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // First, open verification entry screen when driver marks arrival
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VerificationEntryScreen(
                          tripId: widget.trip.id,
                          userName: widget.trip.userName,
                          pickupLocation: widget.trip.pickupLocation,
                        ),
                      )).then((result) {
                        if (result == true) {
                          // Once verified, navigate to ride completion screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code verified — trip started')),
                          );
                          
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => RideCompletionScreen(
                              tripId: widget.trip.id,
                              driverId: widget.trip.driverId ?? '',
                              userId: widget.trip.userId,
                              userName: widget.trip.userName,
                              pickupLocation: widget.trip.pickupLocation,
                              dropoffLocation: widget.trip.dropoffLocation,
                              baseFare: widget.trip.fare,
                              startTime: DateTime.now(),
                            ),
                          ));
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'I have arrived',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
