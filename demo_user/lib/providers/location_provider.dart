import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../models/trip_model.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  // Debounce timer to prevent too many API calls
  Timer? _debounceTimer;
  
  // Legacy string-based locations (for backward compatibility)
  String _pickupLocation = '';
  String _destination = '';
  double? _pickupLat;
  double? _pickupLng;
  double? _destinationLat;
  double? _destinationLng;
  
  // Route information
  List<LatLng> _routeCoordinates = [];
  String _distanceText = '';
  int _distanceValue = 0;
  String _durationText = '';
  int _durationValue = 0;
  
  // New Location model-based locations
  Location? _pickupLocationModel;
  Location? _dropoffLocationModel;
  
  bool _isLoading = false;
  List<PlacePrediction> _predictions = [];
  bool _isSettingDestination = false; // Flag to determine if we're setting destination or pickup

  // Legacy getters (for backward compatibility)
  String get pickupLocation => _pickupLocation;
  String get destination => _destination;
  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;
  double? get destinationLat => _destinationLat;
  double? get destinationLng => _destinationLng;
  
  // Route getters
  List<LatLng> get routeCoordinates => _routeCoordinates;
  String get distanceText => _distanceText;
  int get distanceValue => _distanceValue;
  String get durationText => _durationText;
  int get durationValue => _durationValue;
  
  // New model-based getters
  Location? get pickupLocationModel => _pickupLocationModel;
  Location? get dropoffLocationModel => _dropoffLocationModel;
  
  bool get isLoading => _isLoading;
  List<PlacePrediction> get predictions => _predictions;
  bool get isSettingDestination => _isSettingDestination;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setPickupLocation(String location) {
    _pickupLocation = location;
    notifyListeners();
  }

  void setDestination(String location) {
    _destination = location;
    notifyListeners();
  }

  void setPickupCoordinates(double lat, double lng) {
    _pickupLat = lat;
    _pickupLng = lng;
    notifyListeners();
  }

  void setDestinationCoordinates(double lat, double lng) {
    _destinationLat = lat;
    _destinationLng = lng;
    notifyListeners();
  }
  
  // Method to calculate and update route
  Future<void> updateRoute() async {
    if (_pickupLat != null && _pickupLng != null && _destinationLat != null && _destinationLng != null) {
      try {
        setLoading(true);
        final directions = await _locationService.getDirections(
          _pickupLat!, 
          _pickupLng!, 
          _destinationLat!, 
          _destinationLng!
        );
        
        _routeCoordinates = directions.polylinePoints;
        _distanceText = directions.distanceText;
        _distanceValue = directions.distanceValue;
        _durationText = directions.durationText;
        _durationValue = directions.durationValue;
        
        notifyListeners();
      } catch (e) {
        print('Error calculating route: $e');
        _routeCoordinates = [];
        _distanceText = '';
        _distanceValue = 0;
        _durationText = '';
        _durationValue = 0;
        notifyListeners();
      } finally {
        setLoading(false);
      }
    } else {
      // Clear route if we don't have both start and end points
      _routeCoordinates = [];
      _distanceText = '';
      _distanceValue = 0;
      _durationText = '';
      _durationValue = 0;
      notifyListeners();
    }
  }
  
  // New methods for Location model
  void setPickupLocationModel(Location location) {
    _pickupLocationModel = location;
    // Update legacy fields for backward compatibility
    _pickupLocation = location.formattedAddress;
    _pickupLat = location.latitude;
    _pickupLng = location.longitude;
    notifyListeners();
  }
  
  void setDropoffLocationModel(Location location) {
    _dropoffLocationModel = location;
    // Update legacy fields for backward compatibility
    _destination = location.formattedAddress;
    _destinationLat = location.latitude;
    _destinationLng = location.longitude;
    notifyListeners();
  }

  void setIsSettingDestination(bool value) {
    _isSettingDestination = value;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      print('Getting current location...');
      setLoading(true);
      final position = await _locationService.getCurrentLocation();
      print('Got position: ${position.latitude}, ${position.longitude}');
      final address = await _locationService.getAddressFromCoordinates(position.latitude, position.longitude);
      print('Got address: $address');
      
      setPickupLocation(address);
      setPickupCoordinates(position.latitude, position.longitude);
      print('Location set successfully');
    } catch (e) {
      print('Error getting current location: $e');
      // Show error to user
      // In a real app, you'd show a snackbar or dialog
    } finally {
      setLoading(false);
    }
  }

  Future<void> searchLocations(String query, {bool forDestination = true}) async {
    print('Searching locations for query: $query, forDestination: $forDestination');
    
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _predictions = [];
      notifyListeners();
      return;
    }

    // Set a new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        setLoading(true);
        final results = await _locationService.searchPlaces(query);
        print('Found ${results.length} results');
        _predictions = results;
        _isSettingDestination = forDestination; // Set flag based on which field is being searched
        notifyListeners();
      } catch (e) {
        print('Error searching locations: $e');
        _predictions = [];
        notifyListeners();
      } finally {
        setLoading(false);
      }
    });
  }

  void clearPredictions() {
    _predictions = [];
    notifyListeners();
  }

  Future<void> selectLocation(PlacePrediction prediction) async {
    print('Selecting location: ${prediction.description}');
    try {
      setLoading(true);
      final detail = await _locationService.getPlaceDetail(prediction.placeId);
      print('Got place detail: ${detail.name}, ${detail.lat}, ${detail.lng}');
      
      // Based on the flag, update either pickup or destination
      if (_isSettingDestination) {
        print('Setting destination');
        setDestination(detail.formattedAddress ?? detail.name);
        setDestinationCoordinates(detail.lat, detail.lng);
      } else {
        print('Setting pickup location');
        setPickupLocation(detail.formattedAddress ?? detail.name);
        setPickupCoordinates(detail.lat, detail.lng);
      }
      
      clearPredictions();
      print('Location selection completed');
      
      // Update the route after location selection
      await updateRoute();
    } catch (e) {
      print('Error selecting location: $e');
    } finally {
      setLoading(false);
    }
  }
}