import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class Place {
  String? streetNumber;
  String? street;
  String? city;
  String? province;
  String? postalCode;
  double? latitude;
  double? longitude;

  Place({
    this.streetNumber,
    this.street,
    this.city,
    this.province,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  @override
  String toString() {
    return '$streetNumber, $street, $city, $province, $postalCode';
  }
}

class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlaceApiProvider {
  final client = Client();

  PlaceApiProvider(this.sessionToken);

  final sessionToken;
  final apiKey = 'AIzaSyDeby3Bb48ui1EcYcFSksXDMbRtZ81PU4Q';

  Future<List<Suggestion>> fetchSuggestions(
      String input, String lang, String country) async {
    try {
      String url;
      if (country.isNotEmpty) {
        url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&components=country:$country&key=$apiKey&sessiontoken=$sessionToken';
      } else {
        url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&key=$apiKey&sessiontoken=$sessionToken';
      }
      
      final request = Uri.parse(url);
      final response = await client.get(request);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint(result.toString());
        if (result['status'] == 'OK') {
          // compose suggestions in a list
          return result['predictions']
              .map<Suggestion>(
                  (p) => Suggestion(p['place_id'], p['description']))
              .toList();
        }
        if (result['status'] == 'ZERO_RESULTS') {
          return [];
        }
        throw Exception(result['error_message']);
      } else {
        throw Exception('Failed to fetch suggestion');
      }
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  Future<Place> getPlaceDetailFromId(String placeId) async {
    try {
      final Uri request = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=address_component,geometry&key=$apiKey&sessiontoken=$sessionToken');
      final response = await client.get(request);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint(result.toString());
        if (result['status'] == 'OK') {
          final components =
              result['result']['address_components'] as List<dynamic>;
          // build result
          final place = Place();
          for (var c in components) {
            final List type = c['types'];
            if (type.contains('street_number')) {
              place.streetNumber = c['long_name'];
            }
            if (type.contains('route')) {
              place.street = c['long_name'];
            }
            if (type.contains('locality')) {
              place.city = c['long_name'];
            }
            if (type.contains('administrative_area_level_1')) {
              place.province = c['long_name'];
            }
            if (type.contains('postal_code')) {
              place.postalCode = c['long_name'];
            }
          }
          // try to extract geometry/coordinates if available
          if (result['result'] != null &&
              result['result']['geometry'] != null) {
            final loc = result['result']['geometry']['location'];
            if (loc != null) {
              try {
                place.latitude = (loc['lat'] as num).toDouble();
                place.longitude = (loc['lng'] as num).toDouble();
              } catch (_) {}
            }
          }
          return place;
        }
        throw Exception(result['error_message']);
      } else {
        throw Exception('Failed to fetch suggestion');
      }
    } catch (e) {
      debugPrint(e.toString());
      return Place();
    }
  }

  Future<Map<String, dynamic>> getDirections(double originLat, double originLng, double destLat, double destLng) async {
    try {
      final request = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$apiKey');
      final response = await client.get(request);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('Directions API Response: ${result.toString()}');
        
        if (result['status'] == 'OK' && result['routes'].isNotEmpty) {
          final route = result['routes'][0];
          final overviewPolyline = route['overview_polyline']['points'];
          final distance = route['legs'][0]['distance']['text'];
          final duration = route['legs'][0]['duration']['text'];
          
          return {
            'polyline': overviewPolyline,
            'distance': distance,
            'duration': duration,
            'bounds': {
              'northeast': route['bounds']['northeast'],
              'southwest': route['bounds']['southwest'],
            },
          };
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('Failed to get directions');
      }
    } catch (e) {
      debugPrint('getDirections error: ${e.toString()}');
      rethrow;
    }
  }
}