import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class DriverMapView extends StatefulWidget {
  const DriverMapView({Key? key}) : super(key: key);

  @override
  State<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  GoogleMapController? mapController;
  LocationService locationService = LocationService();
  Position? currentLocation;
  Set<Marker> markers = {};
  StreamSubscription<Position>? positionStream;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = position;
      });

      _updateDriverMarker(position);
      _moveToCurrentLocation(position);

      // Start listening to location updates
      _startLocationUpdates();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        currentLocation = position;
      });
      
      _updateDriverMarker(position);
      _updateDriverLocationInFirestore(position);
    });
  }

  void _updateDriverMarker(Position position) {
    final newMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    setState(() {
      markers = {newMarker};
    });
  }

  void _updateDriverLocationInFirestore(Position position) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;
    
    if (driverId != null) {
      await locationService.updateDriverLocation(
        driverId,
        position.latitude,
        position.longitude,
      );
    }
  }

  void _moveToCurrentLocation(Position position) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return currentLocation != null
        ? GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              
              // Add initial marker if location is available
              if (currentLocation != null && markers.isEmpty) {
                _updateDriverMarker(currentLocation!);
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLocation?.latitude ?? 0, currentLocation?.longitude ?? 0),
              zoom: 15,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}