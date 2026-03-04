import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/trip_model.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  static const String id = 'map_screen';
  
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  TextEditingController _sourceController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  bool _showSourceSuggestions = false;
  bool _showDestinationSuggestions = false;
  List<PlacePrediction> _sourceSuggestions = [];
  List<PlacePrediction> _destinationSuggestions = [];
  Location? _sourceLocation;
  Location? _destinationLocation;

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & Route Planner'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.7128, -74.0060), // Default to New York
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
          // Source and Destination inputs at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      hintText: 'Enter source location',
                      prefixIcon: Icon(Icons.my_location, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: _onSourceChanged,
                    onTap: () {
                      if (_sourceController.text.isNotEmpty && _showSourceSuggestions) {
                        setState(() {
                          _showSourceSuggestions = true;
                        });
                      }
                    },
                  ),
                ),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter destination location',
                      prefixIcon: Icon(Icons.location_pin, color: Colors.red),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: _onDestinationChanged,
                    onTap: () {
                      if (_destinationController.text.isNotEmpty && _showDestinationSuggestions) {
                        setState(() {
                          _showDestinationSuggestions = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Source suggestions overlay
          if (_showSourceSuggestions && _sourceSuggestions.isNotEmpty)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: _buildSuggestionsOverlay(_sourceSuggestions, true),
            ),
            
          // Destination suggestions overlay
          if (_showDestinationSuggestions && _destinationSuggestions.isNotEmpty)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: _buildSuggestionsOverlay(_destinationSuggestions, false),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay(List<PlacePrediction> suggestions, bool isSource) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final result = suggestions[index];
            return ListTile(
              leading: Icon(
                isSource ? Icons.my_location : Icons.location_pin,
                color: isSource ? Colors.green : Colors.red,
              ),
              title: Text(
                result.description,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: result.secondaryText != null 
                  ? Text(
                      result.secondaryText!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
              onTap: () => _selectSuggestion(result, isSource),
              dense: true,
            );
          },
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  
  void _onSourceChanged(String value) async {
    if (value.length > 2) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        await locationProvider.searchLocations(value, forDestination: false);
        
        setState(() {
          _sourceSuggestions = locationProvider.predictions;
          _showSourceSuggestions = _sourceSuggestions.isNotEmpty;
        });
      } catch (e) {
        print('Error searching source locations: $e');
        setState(() {
          _sourceSuggestions = [];
          _showSourceSuggestions = false;
        });
      }
    } else {
      setState(() {
        _sourceSuggestions = [];
        _showSourceSuggestions = false;
      });
    }
  }
  
  void _onDestinationChanged(String value) async {
    if (value.length > 2) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        await locationProvider.searchLocations(value, forDestination: true);
        
        setState(() {
          _destinationSuggestions = locationProvider.predictions;
          _showDestinationSuggestions = _destinationSuggestions.isNotEmpty;
        });
      } catch (e) {
        print('Error searching destination locations: $e');
        setState(() {
          _destinationSuggestions = [];
          _showDestinationSuggestions = false;
        });
      }
    } else {
      setState(() {
        _destinationSuggestions = [];
        _showDestinationSuggestions = false;
      });
    }
  }

  Future<void> _selectSuggestion(PlacePrediction result, bool isSource) async {
    try {
      final locationService = LocationService();
      final placeDetail = await locationService.getPlaceDetail(result.placeId);
      
      final selectedLocation = Location(
        latitude: placeDetail.lat,
        longitude: placeDetail.lng,
        formattedAddress: placeDetail.formattedAddress ?? result.description,
        placeId: result.placeId,
      );
      
      if (isSource) {
        _sourceLocation = selectedLocation;
        _sourceController.text = result.description;
        setState(() {
          _showSourceSuggestions = false;
          _sourceSuggestions = [];
        });
      } else {
        _destinationLocation = selectedLocation;
        _destinationController.text = result.description;
        setState(() {
          _showDestinationSuggestions = false;
          _destinationSuggestions = [];
        });
      }
      
      // Move map to the selected location
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
            zoom: 15,
          ),
        ),
      );
      
      // Update markers
      _updateMarkers();
      
      // If both source and destination are selected, draw route
      if (_sourceLocation != null && _destinationLocation != null) {
        _drawRoute();
      }
    } catch (e) {
      print('Error selecting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _updateMarkers() {
    final Set<Marker> markers = {};
    
    // Add source marker
    if (_sourceLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('source'),
          position: LatLng(_sourceLocation!.latitude, _sourceLocation!.longitude),
          infoWindow: InfoWindow(
            title: 'Source',
            snippet: _sourceLocation!.formattedAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    
    // Add destination marker
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destinationLocation!.latitude, _destinationLocation!.longitude),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationLocation!.formattedAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }
  
  void _drawRoute() {
    if (_sourceLocation != null && _destinationLocation != null) {
      // In a real app, you would use Directions API to get the actual route
      // For now, we'll draw a straight line between source and destination
      final Set<Polyline> polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(_sourceLocation!.latitude, _sourceLocation!.longitude),
            LatLng(_destinationLocation!.latitude, _destinationLocation!.longitude),
          ],
          color: Colors.blue,
          width: 5,
        ),
      };
      
      setState(() {
        _polylines.clear();
        _polylines.addAll(polylines);
      });
      
      // Fit both markers in the camera view
      _fitCameraToBounds();
    }
  }
  
  void _fitCameraToBounds() async {
    if (_sourceLocation != null && _destinationLocation != null) {
      final southwestLat = [_sourceLocation!.latitude, _destinationLocation!.latitude].reduce((a, b) => a < b ? a : b);
      final southwestLng = [_sourceLocation!.longitude, _destinationLocation!.longitude].reduce((a, b) => a < b ? a : b);
      final northeastLat = [_sourceLocation!.latitude, _destinationLocation!.latitude].reduce((a, b) => a > b ? a : b);
      final northeastLng = [_sourceLocation!.longitude, _destinationLocation!.longitude].reduce((a, b) => a > b ? a : b);
      
      // Create camera position that fits both points
      final latSpan = northeastLat - southwestLat;
      final lngSpan = northeastLng - southwestLng;
      
      final center = LatLng(
        (southwestLat + northeastLat) / 2,
        (southwestLng + northeastLng) / 2,
      );
      
      // Calculate zoom level based on span
      final zoom = _calculateZoomLevel(latSpan, lngSpan);
      
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: zoom,
          ),
        ),
      );
    }
  }
  
  double _calculateZoomLevel(double latSpan, double lngSpan) {
    // Convert degrees to meters (approximate calculation)
    final latMeters = latSpan * 111000; // Roughly 111km per degree of latitude
    final lngMeters = lngSpan * 111000 * 0.5; // Longitude varies by latitude
    
    // Determine the larger span
    final maxSpan = latMeters > lngMeters ? latMeters : lngMeters;
    
    // Calculate zoom level based on span
    if (maxSpan > 1000000) return 6; // Very wide area (>1000km)
    if (maxSpan > 500000) return 7;  // Large area (500-1000km)
    if (maxSpan > 200000) return 8;  // Medium-large area (200-500km)
    if (maxSpan > 100000) return 9;  // Large city area (100-200km)
    if (maxSpan > 50000) return 10;  // City area (50-100km)
    if (maxSpan > 20000) return 11;  // Suburban area (20-50km)
    if (maxSpan > 10000) return 12;  // Neighborhood (10-20km)
    if (maxSpan > 5000) return 13;   // Small neighborhood (5-10km)
    if (maxSpan > 2000) return 14;   // Streets (2-5km)
    if (maxSpan > 1000) return 15;   // Blocks (1-2km)
    if (maxSpan > 500) return 16;    // Buildings (0.5-1km)
    if (maxSpan > 200) return 17;    // Close up (<0.5km)
    return 18;                       // Very close up
  }
}