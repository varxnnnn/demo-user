import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'user/code_display_screen.dart';
import '../models/trip_model.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  late StreamSubscription<DocumentSnapshot> _tripSub;
  String? _driverLocationLat;
  String? _driverLocationLng;
  String? _driverCurrentStatus;
  String? _driverName;
  String? _driverId;
  Trip? _updatedTrip;

  @override
  void initState() {
    super.initState();
    // Delay marker setup slightly to ensure map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMapMarkers();
    });
    _startVerificationListener();
    _startDriverLocationTracking();
  }

  bool _showingCodeScreen = false;
  Timer? _locationTimer;
  
  void _startDriverLocationTracking() {
    // Update driver location periodically based on the latest data
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_driverLocationLat != null && _driverLocationLng != null) {
        try {
          final driverLat = double.parse(_driverLocationLat!);
          final driverLng = double.parse(_driverLocationLng!);
          _updateDriverMarker(driverLat, driverLng);
          
          // Move camera to show both pickup and driver positions
          if (mapController != null) {
            _fitMapToRouteWithDriver(LatLng(driverLat, driverLng));
          }
          
          // Check if driver is within 100m radius of user's pickup location
          final distance = _calculateDistance(
            driverLat,
            driverLng,
            widget.trip.pickupLocation.latitude,
            widget.trip.pickupLocation.longitude,
          );
          
          if (distance <= 0.1) { // 0.1 km = 100 meters
            // Driver is within 100m radius, generate code
            await _generateVerificationCode();
          }
        } catch (e) {
          // Handle parsing errors
        }
      }
    });
  }
  
  void _startVerificationListener() {
    _tripSub = FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      
      // Update driver information if available
      if (data['driverId'] != null || data['driverName'] != null) {
        setState(() {
          // Update driver information in local state
          if (data['driverId'] != null) {
            _driverId = data['driverId'];
          }
          
          if (data['driverName'] != null) {
            _driverName = data['driverName'];
          }
          
          // Update status if available
          if (data['status'] != null) {
            _driverCurrentStatus = data['status'];
          }
          
          // Create an updated trip object with new driver info
          _updatedTrip = Trip(
            id: widget.trip.id,
            userId: widget.trip.userId,
            userName: widget.trip.userName,
            pickupLocation: widget.trip.pickupLocation,
            dropoffLocation: widget.trip.dropoffLocation,
            tripType: widget.trip.tripType,
            transportDetails: widget.trip.transportDetails,
            distance: widget.trip.distance,
            estimatedDuration: widget.trip.estimatedDuration,
            fare: widget.trip.fare,
            status: data['status'] != null ? _getTripStatusFromString(data['status']) : widget.trip.status,
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
      
      // Update status if available
      if (data['status'] != null) {
        setState(() {
          _driverCurrentStatus = data['status'];
        });
      }
      
      // Check for verification code
      final verification = data['verification'];
      if (verification != null && verification['code'] != null) {
        if (!_showingCodeScreen && mounted) {
          _showingCodeScreen = true;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CodeDisplayScreen(tripId: widget.trip.id),
          )).then((_) {
            _showingCodeScreen = false;
          });
        }
      }
    });
  }
  
  TripStatus _getTripStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return TripStatus.requested;
      case 'accepted':
        return TripStatus.accepted;
      case 'driver_arrived':
        return TripStatus.driver_arrived;
      case 'in_progress':
        return TripStatus.in_progress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.requested;
    }
  }

  void _setupMapMarkers() {
    // Clear existing markers first
    markers.clear();
    
    // Add pickup marker - ensure it's always added
    print('Adding pickup marker at: ${widget.trip.pickupLocation.latitude}, ${widget.trip.pickupLocation.longitude}');
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.trip.pickupLocation.latitude,
          widget.trip.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.trip.pickupLocation.formattedAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    print('Pickup marker added. Total markers: ${markers.length}');

    // Add dropoff marker
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.trip.dropoffLocation.latitude,
          widget.trip.dropoffLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: widget.trip.dropoffLocation.formattedAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add driver marker if driver location is available
    if (_driverLocationLat != null && _driverLocationLng != null) {
      try {
        final driverLat = double.parse(_driverLocationLat!);
        final driverLng = double.parse(_driverLocationLng!);
        markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(driverLat, driverLng),
            infoWindow: const InfoWindow(
              title: 'Driver Location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      } catch (e) {
        // Handle parsing errors
        print('Error parsing driver location: $e');
      }
    }

    // Draw polyline between pickup and dropoff
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: [
          LatLng(
            widget.trip.pickupLocation.latitude,
            widget.trip.pickupLocation.longitude,
          ),
          LatLng(
            widget.trip.dropoffLocation.latitude,
            widget.trip.dropoffLocation.longitude,
          ),
        ],
      ),
    );
    
    // Update the UI
    if (mounted) {
      setState(() {});
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitMapToRoute();
    // Ensure markers are set up after map is created
    _setupMapMarkers();
  }

  @override
  void dispose() {
    _tripSub?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _fitMapToRoute() {
    if (mapController == null) return;
    
    final bounds = _calculateBounds();
    print('Fitting map to route bounds: $bounds');
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _updateDriverMarker(double lat, double lng) {
    // Remove existing driver marker if present
    markers.removeWhere((marker) => marker.markerId.value == 'driver');
    
    // Add new driver marker
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(
          title: 'Driver Location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    
    // Update the map if controller is available
    if (mounted) {
      setState(() {});
      // Fit the map to include both pickup and driver positions
      _fitMapToRouteWithDriver(LatLng(lat, lng));
    }
  }
  
  void _fitMapToRouteWithDriver(LatLng driverPos) {
    if (markers.isNotEmpty && mapController != null) {
      final bounds = _calculateBoundsWithDriver(driverPos);
      try {
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } catch (e) {
        // Handle case where bounds contain infinite values
        print('Error animating camera: $e');
      }
    }
  }
  
  LatLngBounds _calculateBoundsWithDriver(LatLng driverPos) {
    final pickupLat = widget.trip.pickupLocation.latitude;
    final pickupLng = widget.trip.pickupLocation.longitude;
    final dropoffLat = widget.trip.dropoffLocation.latitude;
    final dropoffLng = widget.trip.dropoffLocation.longitude;
    
    // Find min/max coordinates including driver position
    double minLat = [pickupLat, dropoffLat, driverPos.latitude].reduce((a, b) => a < b ? a : b);
    double maxLat = [pickupLat, dropoffLat, driverPos.latitude].reduce((a, b) => a > b ? a : b);
    double minLng = [pickupLng, dropoffLng, driverPos.longitude].reduce((a, b) => a < b ? a : b);
    double maxLng = [pickupLng, dropoffLng, driverPos.longitude].reduce((a, b) => a > b ? a : b);
    
    // Add some padding to the bounds
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.005, minLng - 0.005),
      northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
    );
    
    return bounds;
  }

  LatLngBounds _calculateBounds() {
    final pickupLat = widget.trip.pickupLocation.latitude;
    final pickupLng = widget.trip.pickupLocation.longitude;
    final dropoffLat = widget.trip.dropoffLocation.latitude;
    final dropoffLng = widget.trip.dropoffLocation.longitude;

    double minLat = pickupLat < dropoffLat ? pickupLat : dropoffLat;
    double maxLat = pickupLat > dropoffLat ? pickupLat : dropoffLat;
    double minLng = pickupLng < dropoffLng ? pickupLng : dropoffLng;
    double maxLng = pickupLng > dropoffLng ? pickupLng : dropoffLng;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    return bounds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.trip.status == TripStatus.in_progress ||
        widget.trip.status == TripStatus.driver_arrived ||
        widget.trip.status == TripStatus.accepted) {
      return _buildOngoingTripMap();
    } else if (widget.trip.status == TripStatus.completed) {
      return _buildCompletedTripDetails();
    } else if (widget.trip.status == TripStatus.requested) {
      return _buildRequestedTripDetails();
    } else {
      return _buildCancelledTripDetails();
    }
  }

  // Map view for ongoing/in-progress trips
  Widget _buildOngoingTripMap() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.trip.pickupLocation.latitude,
              widget.trip.pickupLocation.longitude,
            ),
            zoom: 14.0,
          ),
          markers: markers,
          polylines: polylines,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.trip.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(widget.trip.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Driver info with verification code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Driver Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 28,
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
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_driverName != null || _updatedTrip?.driverName != null)
                                  Text(
                                    'ID: ${_driverId ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (_driverLocationLat != null && _driverLocationLng != null)
                                  Text(
                                    'Driver is ${_getDistanceFromDriver()} away',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Verification code section
                      if (_driverName != null || _updatedTrip?.driverName != null) ...[
                        const SizedBox(height: 16),
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
                              Row(
                                children: [
                                  const Icon(Icons.lock, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Verification Code',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Share this code with your driver to start the trip:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).get(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                                    final verification = data?['verification'];
                                    if (verification != null && verification['code'] != null) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.lock, color: Colors.blue, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Code: ',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            Text(
                                              verification['code'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                  return const Text(
                                    'Code will be generated when driver arrives',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Distance and duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: '${widget.trip.distance.toStringAsFixed(1)} km',
                    ),
                    _buildDetailItem(
                      icon: Icons.schedule,
                      label: 'Duration',
                      value: '${widget.trip.estimatedDuration} min',
                    ),
                    _buildDetailItem(
                      icon: Icons.attach_money,
                      label: 'Fare',
                      value: '${widget.trip.fare.toStringAsFixed(0)} ৳',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Detailed view for completed trips
  Widget _buildCompletedTripDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Completed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Completed on ${_formatDate(widget.trip.completedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Route section
          const Text(
            'Route',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.blue,
            label: 'Pickup',
            address: widget.trip.pickupLocation.formattedAddress,
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.green,
            label: 'Dropoff',
            address: widget.trip.dropoffLocation.formattedAddress,
          ),
          const SizedBox(height: 24),

          // Trip details
          const Text(
            'Trip Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Distance', '${widget.trip.distance.toStringAsFixed(1)} km'),
          _buildDetailRow('Duration', '${widget.trip.estimatedDuration} minutes'),
          _buildDetailRow('Fare', '${widget.trip.fare.toStringAsFixed(0)} ৳'),
          _buildDetailRow('Trip Type', _getTripTypeName(widget.trip.tripType)),
          const SizedBox(height: 24),

          // Driver details
          if (widget.trip.driverName != null) ...[
            const Text(
              'Driver Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Name', widget.trip.driverName!),
            if (widget.trip.driverName != null)
              _buildDetailRow('Completed At', _formatDate(widget.trip.completedAt!)),
          ],

          // Transport details
          if (widget.trip.tripType == TripType.objectTransport &&
              widget.trip.transportDetails.objectType != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Object Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Type', _getObjectTypeName(widget.trip.transportDetails.objectType!)),
            if (widget.trip.transportDetails.objectDescription != null)
              _buildDetailRow('Description', widget.trip.transportDetails.objectDescription!),
            if (widget.trip.transportDetails.weight != null)
              _buildDetailRow('Weight', '${widget.trip.transportDetails.weight} kg'),
            if (widget.trip.transportDetails.isFragile == true)
              _buildDetailRow('Fragile', 'Yes ⚠️'),
          ],

          // Passenger details
          if (widget.trip.tripType == TripType.peopleTransport &&
              widget.trip.transportDetails.numberOfPassengers != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Passenger Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Passengers', '${widget.trip.transportDetails.numberOfPassengers} person(s)'),
            if (widget.trip.transportDetails.passengerNames != null &&
                widget.trip.transportDetails.passengerNames!.isNotEmpty)
              _buildDetailRow(
                'Names',
                widget.trip.transportDetails.passengerNames!.join(', '),
              ),
          ],
        ],
      ),
    );
  }

  // Simple view for requested trips
  Widget _buildRequestedTripDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waiting status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waiting for Driver',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Requested at ${_formatDate(widget.trip.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Route section
          const Text(
            'Route',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.blue,
            label: 'Pickup',
            address: widget.trip.pickupLocation.formattedAddress,
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.green,
            label: 'Dropoff',
            address: widget.trip.dropoffLocation.formattedAddress,
          ),
          const SizedBox(height: 24),

          // Trip summary
          const Text(
            'Trip Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${widget.trip.distance.toStringAsFixed(1)} km',
              ),
              _buildDetailItem(
                icon: Icons.schedule,
                label: 'Est. Duration',
                value: '${widget.trip.estimatedDuration} min',
              ),
              _buildDetailItem(
                icon: Icons.attach_money,
                label: 'Fare',
                value: '${widget.trip.fare.toStringAsFixed(0)} ৳',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // View for cancelled trips
  Widget _buildCancelledTripDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cancelled status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Cancelled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(widget.trip.status),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Route section
          const Text(
            'Route',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.blue,
            label: 'Pickup',
            address: widget.trip.pickupLocation.formattedAddress,
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            color: Colors.green,
            label: 'Dropoff',
            address: widget.trip.dropoffLocation.formattedAddress,
          ),
          const SizedBox(height: 24),

          // Trip details
          _buildDetailRow('Fare', '${widget.trip.fare.toStringAsFixed(0)} ৳'),
          _buildDetailRow('Distance', '${widget.trip.distance.toStringAsFixed(1)} km'),
          _buildDetailRow('Est. Duration', '${widget.trip.estimatedDuration} minutes'),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600]!,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.requested:
        return Colors.orange;
      case TripStatus.accepted:
        return Colors.blue;
      case TripStatus.driver_arrived:
        return Colors.purple;
      case TripStatus.in_progress:
        return Colors.indigo;
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.requested:
        return 'Requested';
      case TripStatus.accepted:
        return 'Accepted';
      case TripStatus.driver_arrived:
        return 'Driver Arrived';
      case TripStatus.in_progress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getTripTypeName(TripType type) {
    switch (type) {
      case TripType.objectTransport:
        return 'Object Transport';
      case TripType.peopleTransport:
        return 'People Transport';
    }
  }

  String _getObjectTypeName(ObjectType type) {
    switch (type) {
      case ObjectType.document:
        return 'Document';
      case ObjectType.package:
        return 'Package';
      case ObjectType.furniture:
        return 'Furniture';
      case ObjectType.electronics:
        return 'Electronics';
      case ObjectType.clothing:
        return 'Clothing';
      case ObjectType.food:
        return 'Food';
      case ObjectType.medical:
        return 'Medical';
      case ObjectType.other:
        return 'Other';
    }
  }

  String _getDistanceFromDriver() {
    if (_driverLocationLat != null && _driverLocationLng != null) {
      try {
        final driverLat = double.parse(_driverLocationLat!);
        final driverLng = double.parse(_driverLocationLng!);
        
        // Calculate distance between driver and pickup location
        final distance = _calculateDistance(
          driverLat,
          driverLng,
          widget.trip.pickupLocation.latitude,
          widget.trip.pickupLocation.longitude,
        );
        
        // Return formatted distance
        if (distance < 1.0) {
          return '${(distance * 1000).round()} meters';
        } else {
          return '${distance.toStringAsFixed(1)} km';
        }
      } catch (e) {
        return 'calculating...';
      }
    }
    return 'unknown';
  }
  
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0; // Earth radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * 
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _generateVerificationCode() async {
    // Check if code already exists to avoid regenerating
    final tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).get();
    final data = tripDoc.data();
    
    if (data != null && data['verification'] != null && data['verification']['code'] != null) {
      // Code already exists, don't generate a new one
      return;
    }
    
    // Generate a random 6-digit code
    final random = math.Random();
    final code = random.nextInt(900000) + 100000; // Generates a number between 100000-999999
    
    // Update the trip with the verification code
    await FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).update({
      'verification': {
        'code': code.toString(),
        'generatedAt': FieldValue.serverTimestamp(),
        'status': 'waiting_for_driver_input',
      }
    });
    
    // Also update in rideRequests for consistency
    await FirebaseFirestore.instance.collection('rideRequests').doc(widget.trip.id).update({
      'verification': {
        'code': code.toString(),
        'generatedAt': FieldValue.serverTimestamp(),
        'status': 'waiting_for_driver_input',
      }
    });
    
    // Show the code to the user
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Verification Code Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share this code with your driver:'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Please share this code with your driver to start the trip.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
