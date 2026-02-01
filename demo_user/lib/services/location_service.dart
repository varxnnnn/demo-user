import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static const String googleMapsApiKey = 'AIzaSyDeby3Bb48ui1EcYcFSksXDMbRtZ81PU4Q';
  
  // Get current user location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue accessing the position.
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you would need to request permissions again.
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
        return address.trim().replaceAll(', ,', ', ').replaceAll(',,', ',');
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unable to get address';
    }
  }

  // Search for places using Google Places Autocomplete API (better for real-time suggestions)
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    // Using Google Places Autocomplete API for better real-time suggestions
    final String encodedQuery = Uri.encodeComponent(query);
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$googleMapsApiKey&types=geocode';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> predictions = jsonData['predictions'];
        
        return predictions.map((prediction) => PlacePrediction.fromAutocompleteJson(prediction)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load places');
      }
    } catch (e) {
      print('Error searching places: $e');
      throw Exception('Error searching places: $e');
    }
  }

  // Get place details by place ID
  Future<PlaceDetail> getPlaceDetail(String placeId) async {
    final String encodedPlaceId = Uri.encodeComponent(placeId);
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$encodedPlaceId&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final result = jsonData['result'];
        
        return PlaceDetail.fromJson(result);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load place details');
      }
    } catch (e) {
      print('Error getting place details: $e');
      throw Exception('Error getting place details: $e');
    }
  }
  
  // Get directions between two points
  Future<DirectionsResponse> getDirections(double originLat, double originLng, double destLat, double destLng) async {
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 'OK' && jsonData['routes'].length > 0) {
          final route = jsonData['routes'][0];
          final legs = route['legs'][0];
          
          // Extract polyline points
          final overviewPolyline = route['overview_polyline']['points'];
          
          // Extract distance and duration
          final distanceText = legs['distance']['text'];
          final distanceValue = legs['distance']['value']; // in meters
          final durationText = legs['duration']['text'];
          final durationValue = legs['duration']['value']; // in seconds
          
          return DirectionsResponse(
            polylinePoints: decodePolyline(overviewPolyline),
            distanceText: distanceText,
            distanceValue: distanceValue,
            durationText: durationText,
            durationValue: durationValue,
          );
        } else {
          throw Exception('No route found');
        }
      } else {
        print('Directions API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get directions');
      }
    } catch (e) {
      print('Error getting directions: $e');
      throw Exception('Error getting directions: $e');
    }
  }
  
  // Decode polyline points from Google Directions API
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }

    return poly;
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String? secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    this.secondaryText,
  });

  // Constructor for autocomplete API response
  factory PlacePrediction.fromAutocompleteJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
      secondaryText: json['structured_formatting'] != null 
          ? json['structured_formatting']['secondary_text'] 
          : null,
    );
  }

  // Constructor for text search API response
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
      secondaryText: structuredFormatting != null ? structuredFormatting['secondary_text'] : null,
    );
  }
}

class PlaceDetail {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String? formattedAddress;

  PlaceDetail({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry['location'];
    
    return PlaceDetail(
      placeId: json['place_id'],
      name: json['name'],
      lat: location['lat'].toDouble(),
      lng: location['lng'].toDouble(),
      formattedAddress: json['formatted_address'],
    );
  }
}

class DirectionsResponse {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final int distanceValue; // in meters
  final String durationText;
  final int durationValue; // in seconds

  DirectionsResponse({
    required this.polylinePoints,
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationValue,
  });
}