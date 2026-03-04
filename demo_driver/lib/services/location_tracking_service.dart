import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription<Position> _locationSubscription;
  
  // Singleton pattern
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  
  factory LocationTrackingService() {
    return _instance;
  }
  
  LocationTrackingService._internal();

  /// Start tracking driver location for a specific trip
  Future<void> startDriverLocationTracking(
    String driverId,
    String tripId,
  ) async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Configure location settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update every 10 meters
      );

      // Start tracking location
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _updateDriverLocationOnFirestore(driverId, tripId, position);
      });
    } catch (e) {
      print('Error starting location tracking: $e');
      rethrow;
    }
  }

  /// Stop tracking driver location
  Future<void> stopDriverLocationTracking() async {
    try {
      await _locationSubscription.cancel();
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  /// Update driver location on Firestore
  Future<void> _updateDriverLocationOnFirestore(
    String driverId,
    String tripId,
    Position position,
  ) async {
    try {
      // Update in trips collection
      await _firestore.collection('trips').doc(tripId).update({
        'driverLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // Also update driver's current location
      await _firestore.collection('drivers').doc(driverId).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  /// Get driver location stream for a specific trip (for user to see driver location)
  Stream<Map<String, dynamic>?> getDriverLocationStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          return data?['driverLocation'];
        });
  }

  /// Get user location stream (for driver to see user location)
  Stream<Map<String, dynamic>?> getUserLocationStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          return {
            'latitude': data?['from']?['latitude'],
            'longitude': data?['from']?['longitude'],
            'address': data?['from']?['address'],
          };
        });
  }

  /// Get current user location
  Future<Position> getCurrentUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      print('Error getting current location: $e');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double long1,
    double lat2,
    double long2,
  ) {
    return Geolocator.distanceBetween(lat1, long1, lat2, long2) / 1000;
  }

  /// Calculate ETA in minutes based on distance and average speed
  int calculateETA(double distanceKm, {double avgSpeedKmph = 40}) {
    return (distanceKm / avgSpeedKmph * 60).ceil();
  }
}
