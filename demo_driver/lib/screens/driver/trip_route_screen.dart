
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class TripRouteScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  const TripRouteScreen({
    Key? key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
  }) : super(key: key);

  @override
  _TripRouteScreenState createState() => _TripRouteScreenState();
}

class _TripRouteScreenState extends State<TripRouteScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double _totalDistance = 0.0;
  LatLng? _driverLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
      });
      _createMarkers();
      _createPolylines();
      _calculateTotalDistance();
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  void _createMarkers() {
    _markers.add(Marker(
      markerId: MarkerId('pickup'),
      position: LatLng(widget.pickupLat, widget.pickupLng),
      infoWindow: InfoWindow(title: 'Pickup'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));
    _markers.add(Marker(
      markerId: MarkerId('dropoff'),
      position: LatLng(widget.dropoffLat, widget.dropoffLng),
      infoWindow: InfoWindow(title: 'Dropoff'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
    if (_driverLocation != null) {
      _markers.add(Marker(
        markerId: MarkerId('driver'),
        position: _driverLocation!,
        infoWindow: InfoWindow(title: 'Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
  }

  void _createPolylines() {
    if (_driverLocation != null) {
      _polylines.add(Polyline(
        polylineId: PolylineId('driver_to_pickup'),
        color: Colors.blue,
        width: 5,
        points: [
          _driverLocation!,
          LatLng(widget.pickupLat, widget.pickupLng),
        ],
      ));
    }
    _polylines.add(Polyline(
      polylineId: PolylineId('pickup_to_dropoff'),
      color: Colors.purple,
      width: 5,
      points: [
        LatLng(widget.pickupLat, widget.pickupLng),
        LatLng(widget.dropoffLat, widget.dropoffLng),
      ],
    ));
  }

  void _calculateTotalDistance() {
    if (_driverLocation != null) {
      double driverToPickupDistance = _calculateDistance(
        _driverLocation!.latitude,
        _driverLocation!.longitude,
        widget.pickupLat,
        widget.pickupLng,
      );
      double pickupToDropoffDistance = _calculateDistance(
        widget.pickupLat,
        widget.pickupLng,
        widget.dropoffLat,
        widget.dropoffLng,
      );
      setState(() {
        _totalDistance = driverToPickupDistance + pickupToDropoffDistance;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Route'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          if (_totalDistance > 0)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    )
                  ],
                ),
                child: Text(
                  'Total Distance: ${_totalDistance.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
