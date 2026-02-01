import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/trip_model.dart';
import '../services/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final bool isPickup;
  final Location? initialLocation;
  final Location? destinationLocation;

  const MapSelectionScreen({
    Key? key,
    required this.isPickup,
    this.initialLocation,
    this.destinationLocation,
  }) : super(key: key);

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  List<PlacePrediction> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!.formattedAddress ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickup ? 'Select Pickup Location' : 'Select Drop-off Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              try {
                await locationProvider.getCurrentLocation();
                // Use the provider's coordinates for pickup
                if (locationProvider.pickupLat != null && locationProvider.pickupLng != null) {
                  mapController.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          locationProvider.pickupLat!,
                          locationProvider.pickupLng!,
                        ),
                        zoom: 15,
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error getting current location: $e');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation != null
                  ? LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude)
                  : const LatLng(40.7128, -74.0060), // Default to New York
              zoom: 15,
            ),
            markers: _markers,
            polylines: widget.destinationLocation != null ? _polylines : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
          // Search bar at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
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
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a location',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                onChanged: _onSearchChanged,
                onTap: () {
                  if (_searchController.text.isNotEmpty && _showSuggestions) {
                    setState(() {
                      _showSuggestions = true;
                    });
                  }
                },
              ),
            ),
          ),
          // Suggestions overlay
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: _buildSuggestionsOverlay(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Confirm the selected location
          _confirmLocation();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check),
        label: Text(widget.isPickup ? 'Set Pickup' : 'Set Drop-off'),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
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
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final result = _suggestions[index];
            return ListTile(
              leading: Icon(
                widget.isPickup ? Icons.my_location : Icons.location_pin,
                color: widget.isPickup ? Colors.green : Colors.red,
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
              onTap: () => _selectSuggestion(result),
              dense: true,
            );
          },
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    
    // Add initial markers if locations are provided
    if (widget.initialLocation != null) {
      _addMarker(
        id: widget.isPickup ? 'pickup' : 'dropoff',
        position: LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude),
        title: widget.isPickup ? 'Current Pickup' : 'Current Drop-off',
        snippet: widget.initialLocation!.formattedAddress ?? '',
        color: widget.isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
      );
    }
    
    if (widget.destinationLocation != null) {
      _addMarker(
        id: 'destination',
        position: LatLng(widget.destinationLocation!.latitude, widget.destinationLocation!.longitude),
        title: 'Destination',
        snippet: widget.destinationLocation!.formattedAddress ?? '',
        color: BitmapDescriptor.hueRed,
      );
      
      // Draw route if both locations are provided
      if (widget.initialLocation != null) {
        _drawRouteBetweenLocations();
      }
    }
  }
  
  void _addMarker({
    required String id,
    required LatLng position,
    required String title,
    required String snippet,
    required double color,
  }) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: title, snippet: snippet),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
        ),
      );
    });
  }
  
  void _onSearchChanged(String value) async {
    if (value.length > 2) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        await locationProvider.searchLocations(value, forDestination: !widget.isPickup);
        
        setState(() {
          _suggestions = locationProvider.predictions;
          _showSuggestions = _suggestions.isNotEmpty;
        });
      } catch (e) {
        print('Error searching locations: $e');
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }
  
  Future<void> _selectSuggestion(PlacePrediction result) async {
    try {
      final locationService = LocationService();
      final placeDetail = await locationService.getPlaceDetail(result.placeId);
      
      final selectedLocation = Location(
        latitude: placeDetail.lat,
        longitude: placeDetail.lng,
        formattedAddress: placeDetail.formattedAddress ?? result.description,
        placeId: result.placeId,
      );
      
      _searchController.text = result.description;
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      
      // Move map to the selected location
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
            zoom: 15,
          ),
        ),
      );
      
      // Clear and add the new marker
      setState(() {
        _markers.clear();
        
        // Add the selected location marker
        _addMarker(
          id: widget.isPickup ? 'pickup' : 'dropoff',
          position: LatLng(selectedLocation.latitude, selectedLocation.longitude),
          title: widget.isPickup ? 'Selected Pickup' : 'Selected Drop-off',
          snippet: selectedLocation.formattedAddress,
          color: widget.isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        );
        
        // If viewing route, also add destination marker
        if (widget.destinationLocation != null) {
          _addMarker(
            id: 'destination',
            position: LatLng(widget.destinationLocation!.latitude, widget.destinationLocation!.longitude),
            title: 'Destination',
            snippet: widget.destinationLocation!.formattedAddress ?? '',
            color: BitmapDescriptor.hueRed,
          );
        }
      });
      
      // If both locations are provided, draw route
      if (widget.destinationLocation != null) {
        _drawRouteBetweenLocations();
      }
    } catch (e) {
      print('Error selecting location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _drawRouteBetweenLocations() {
    if (widget.initialLocation != null && widget.destinationLocation != null) {
      final Set<Polyline> polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude),
            LatLng(widget.destinationLocation!.latitude, widget.destinationLocation!.longitude),
          ],
          color: Colors.blue,
          width: 5,
        ),
      };
      
      setState(() {
        _polylines.clear();
        _polylines.addAll(polylines);
      });
    }
  }
  
  void _confirmLocation() {
    if (_searchController.text.isEmpty) {
      // For now, just return a default location or show an error
      // In a real app, we would get the current map position
      // But this requires a callback to get the current camera position
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a location or enter an address'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    } else if (widget.initialLocation != null && 
               _searchController.text == widget.initialLocation!.formattedAddress) {
      // Same as initial location, return it
      Navigator.pop(context, widget.initialLocation!);
      return;
    } else {
      // Try to match with suggestions
      final matchingSuggestion = _suggestions.firstWhere(
        (s) => s.description == _searchController.text,
        orElse: () => PlacePrediction(
          placeId: '',
          description: _searchController.text,
          secondaryText: null,
        ),
      );
      
      if (matchingSuggestion.placeId.isNotEmpty) {
        // We have a selected suggestion, get its details
        _getLocationFromSuggestion(matchingSuggestion);
      } else {
        // No matching suggestion, just return the text as location
        final selectedLocation = Location(
          latitude: widget.initialLocation?.latitude ?? 0.0,
          longitude: widget.initialLocation?.longitude ?? 0.0,
          formattedAddress: _searchController.text,
          placeId: '',
        );
        
        Navigator.pop(context, selectedLocation);
      }
    }
  }
  
  Future<void> _getLocationFromSuggestion(PlacePrediction suggestion) async {
    try {
      final locationService = LocationService();
      final placeDetail = await locationService.getPlaceDetail(suggestion.placeId);
      
      final selectedLocation = Location(
        latitude: placeDetail.lat,
        longitude: placeDetail.lng,
        formattedAddress: placeDetail.formattedAddress ?? suggestion.description,
        placeId: suggestion.placeId,
      );
      
      Navigator.pop(context, selectedLocation);
    } catch (e) {
      print('Error getting place detail: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Fallback: return a location with the text
      final selectedLocation = Location(
        latitude: widget.initialLocation?.latitude ?? 0.0,
        longitude: widget.initialLocation?.longitude ?? 0.0,
        formattedAddress: suggestion.description,
        placeId: suggestion.placeId,
      );
      
      Navigator.pop(context, selectedLocation);
    }
  }
}