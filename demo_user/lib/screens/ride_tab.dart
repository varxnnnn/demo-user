import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class RideTab extends StatefulWidget {
  const RideTab({Key? key}) : super(key: key);

  @override
  State<RideTab> createState() => _RideTabState();
}

class _RideTabState extends State<RideTab> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    try {
      await locationProvider.getCurrentLocation();
      _updateMarkers(locationProvider);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _getInitialCameraPosition(locationProvider),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateMarkers(Provider.of<LocationProvider>(context, listen: false));
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

  void _updateMarkers(LocationProvider locationProvider) {
    final Set<Marker> markers = {};

    // Add user's current location marker
    if (locationProvider.pickupLat != null && locationProvider.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(locationProvider.pickupLat!, locationProvider.pickupLng!),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: locationProvider.pickupLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }
}