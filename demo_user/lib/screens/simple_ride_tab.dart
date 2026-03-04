import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import 'trip_creation_screen.dart';
import 'address_search_screen.dart';

class SimpleRideTab extends StatefulWidget {
  const SimpleRideTab({Key? key}) : super(key: key);

  @override
  State<SimpleRideTab> createState() => _SimpleRideTabState();
}

class _SimpleRideTabState extends State<SimpleRideTab> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Ride type selection
  bool _isCurrentRide = true; // true for current ride, false for scheduled ride
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    try {
      await locationProvider.getCurrentLocation();
      _updateMarkers();
      await locationProvider.updateRoute(); // Update route after getting current location
      _updatePolylines();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // Earth's diameter in kilometers * arcsin
  }
  
  double _getZoomLevel(double distanceInKm) {
    if (distanceInKm <= 1) return 16.0; // Very close
    if (distanceInKm <= 5) return 14.0; // Close
    if (distanceInKm <= 10) return 12.0; // Medium
    if (distanceInKm <= 50) return 10.0; // Far
    if (distanceInKm <= 100) return 8.0;  // Very far
    return 6.0; // Extremely far
  }
  
  Widget _buildRideTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCurrentRide = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isCurrentRide ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isCurrentRide ? Colors.blue : Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: _isCurrentRide ? Colors.white : Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Ride',
                          style: TextStyle(
                            color: _isCurrentRide ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Available now',
                          style: TextStyle(
                            color: _isCurrentRide ? Colors.white70 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCurrentRide = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_isCurrentRide ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isCurrentRide ? Colors.green : Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: !_isCurrentRide ? Colors.white : Colors.green,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scheduled Ride',
                          style: TextStyle(
                            color: !_isCurrentRide ? Colors.white : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan ahead',
                          style: TextStyle(
                            color: !_isCurrentRide ? Colors.white70 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isCurrentRide) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled ride will be confirmed 30 minutes before pickup time',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDateTimePicker(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Current ride will be initiated immediately if drivers are available',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Date & Time',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${_scheduledDateTime.day}/${_scheduledDateTime.month}/${_scheduledDateTime.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${_scheduledDateTime.hour.toString().padLeft(2, '0')}:${_scheduledDateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _scheduledDateTime) {
      setState(() {
        _scheduledDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _scheduledDateTime.hour,
          _scheduledDateTime.minute,
        );
      });
    }
  }
  
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
    );
    
    if (picked != null) {
      setState(() {
        _scheduledDateTime = DateTime(
          _scheduledDateTime.year,
          _scheduledDateTime.month,
          _scheduledDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }
  
  void _bookRide() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    // Navigate directly to the trip creation screen without checking driver availability
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripCreationScreen(
        pickupLocation: locationProvider.pickupLocation,
        destination: locationProvider.destination,
        pickupLat: locationProvider.pickupLat ?? 0.0,
        pickupLng: locationProvider.pickupLng ?? 0.0,
        destinationLat: locationProvider.destinationLat ?? 0.0,
        destinationLng: locationProvider.destinationLng ?? 0.0,
        isCurrentRide: _isCurrentRide,
      )),
    );
  }
  
  void _moveCameraToShowBothLocations(LatLng startLocation, LatLng endLocation) async {
    // Move camera to fit both points in the viewport
    try {
      // Calculate the zoom level based on the distance between points
      double distanceInKm = _calculateDistance(startLocation.latitude, startLocation.longitude, endLocation.latitude, endLocation.longitude);
      double zoomLevel = _getZoomLevel(distanceInKm);
      
      // Move to the center point and set appropriate zoom
      final center = LatLng(
        (startLocation.latitude + endLocation.latitude) / 2,
        (startLocation.longitude + endLocation.longitude) / 2,
      );
      
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(center, zoomLevel),
      );
    } catch (e) {
      // If calculation fails, fall back to center approach
      final center = LatLng(
        (startLocation.latitude + endLocation.latitude) / 2,
        (startLocation.longitude + endLocation.longitude) / 2,
      );
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(center, 12),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Map placeholder (upper half)
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _getInitialCameraPosition(locationProvider),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              onTap: (LatLng tappedPoint) => _handleMapTap(tappedPoint, locationProvider),
            ),
          ),
          
          // Location selection (lower half)
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start Location
                    _buildLocationRow(
                      icon: Icons.my_location,
                      color: Colors.blue,
                      label: 'Start Location',
                      location: locationProvider.pickupLocation.isNotEmpty
                          ? locationProvider.pickupLocation
                          : 'Current Location',
                      isStartLocation: true,
                      locationProvider: locationProvider,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Swap button
                    Align(
                      alignment: Alignment.center,
                      child: IconButton(
                        onPressed: () {
                          // Swap start and destination
                          final tempLocation = locationProvider.pickupLocation;
                          final tempLat = locationProvider.pickupLat;
                          final tempLng = locationProvider.pickupLng;
                          
                          // Set start as destination
                          locationProvider.setPickupLocation(locationProvider.destination);
                          locationProvider.setPickupCoordinates(
                            locationProvider.destinationLat ?? 0.0,
                            locationProvider.destinationLng ?? 0.0,
                          );
                          
                          // Set destination as start
                          locationProvider.setDestination(tempLocation);
                          locationProvider.setDestinationCoordinates(
                            tempLat ?? 0.0,
                            tempLng ?? 0.0,
                          );
                          
                          // Refresh markers
                          _updateMarkers();
                          
                          // Update route after swap
                          locationProvider.updateRoute();
                          _updatePolylines();
                          
                          // Move camera to show both locations
                          if (locationProvider.pickupLat != null && 
                              locationProvider.pickupLng != null &&
                              locationProvider.destinationLat != null &&
                              locationProvider.destinationLng != null) {
                            _moveCameraToShowBothLocations(
                              LatLng(locationProvider.pickupLat!, locationProvider.pickupLng!),
                              LatLng(locationProvider.destinationLat!, locationProvider.destinationLng!),
                            );
                          }
                        },
                        icon: const Icon(Icons.swap_vert),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Destination Location
                    _buildLocationRow(
                      icon: Icons.location_pin,
                      color: Colors.green,
                      label: 'Destination',
                      location: locationProvider.destination.isNotEmpty
                          ? locationProvider.destination
                          : 'Tap map to select destination',
                      isStartLocation: false,
                      locationProvider: locationProvider,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Ride Type Selection
                    _buildRideTypeSelection(),
                    
                    const SizedBox(height: 16),
                    
                    // Route Information
                    if (locationProvider.distanceText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Distance:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  locationProvider.distanceText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Duration:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  locationProvider.durationText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Book Ride Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: locationProvider.pickupLat != null &&
                                locationProvider.pickupLng != null &&
                                locationProvider.destinationLat != null &&
                                locationProvider.destinationLng != null
                            ? () {
                                _bookRide();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCurrentRide ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isCurrentRide ? 'BOOK CURRENT RIDE' : 'SCHEDULE RIDE',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String location,
    required bool isStartLocation,
    required LocationProvider locationProvider,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isStartLocation) {
          // For start location, use current location or address search
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddressSearchScreen(),
            ),
          );
          
          if (result != null && mounted) {
            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
            locationProvider.setPickupLocation(result.address);
            locationProvider.setPickupCoordinates(
              result.coordinates.latitude,
              result.coordinates.longitude,
            );
            _updateMarkers();
            await locationProvider.updateRoute();
            _updatePolylines();
            
            // Move camera to show both locations
            if (locationProvider.destinationLat != null && 
                locationProvider.destinationLng != null) {
              _moveCameraToShowBothLocations(
                result.coordinates,
                LatLng(locationProvider.destinationLat!, locationProvider.destinationLng!),
              );
            }
          }
        } else {
          // For destination, use address search
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddressSearchScreen(),
            ),
          );
          
          if (result != null && mounted) {
            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
            locationProvider.setDestination(result.address);
            locationProvider.setDestinationCoordinates(
              result.coordinates.latitude,
              result.coordinates.longitude,
            );
            _updateMarkers();
            await locationProvider.updateRoute();
            _updatePolylines();
            
            // Move camera to show both locations
            if (locationProvider.pickupLat != null && 
                locationProvider.pickupLng != null) {
              _moveCameraToShowBothLocations(
                LatLng(locationProvider.pickupLat!, locationProvider.pickupLng!),
                result.coordinates,
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateMarkers();
  }
  
  CameraPosition _getInitialCameraPosition(LocationProvider locationProvider) {
    if (locationProvider.pickupLat != null && locationProvider.pickupLng != null) {
      return CameraPosition(
        target: LatLng(locationProvider.pickupLat!, locationProvider.pickupLng!),
        zoom: 15,
      );
    } else {
      // Default to New York
      return const CameraPosition(
        target: LatLng(40.7128, -74.0060),
        zoom: 12,
      );
    }
  }
  
  void _updateMarkers() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final Set<Marker> markers = {};

    // Add start location marker
    if (locationProvider.pickupLat != null && locationProvider.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(locationProvider.pickupLat!, locationProvider.pickupLng!),
          infoWindow: InfoWindow(
            title: 'Start Location',
            snippet: locationProvider.pickupLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add destination marker
    if (locationProvider.destinationLat != null && locationProvider.destinationLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(locationProvider.destinationLat!, locationProvider.destinationLng!),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: locationProvider.destination,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }
  
  void _updatePolylines() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final Set<Polyline> polylines = {};

    // Add route polyline if available
    if (locationProvider.routeCoordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: locationProvider.routeCoordinates,
          color: Colors.black,
          width: 6,
        ),
      );
    }

    setState(() {
      _polylines.clear();
      _polylines.addAll(polylines);
    });
  }
  
  void _handleMapTap(LatLng tappedPoint, LocationProvider locationProvider) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting location details...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Get address from coordinates using the location service
      final locationService = LocationService();
      final address = await locationService.getAddressFromCoordinates(tappedPoint.latitude, tappedPoint.longitude);
      
      // Update destination in the provider
      locationProvider.setDestination(address);
      locationProvider.setDestinationCoordinates(tappedPoint.latitude, tappedPoint.longitude);
      
      // Update markers to show the new destination
      _updateMarkers();
      
      // Update route after destination selection
      await locationProvider.updateRoute();
      _updatePolylines();
      
      // Animate camera to the tapped location
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(tappedPoint, 15),
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destination set to: $address'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error handling map tap: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}