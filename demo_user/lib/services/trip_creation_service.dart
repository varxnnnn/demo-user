import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripCreationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createTrip({
    required String userId,
    required String userName,
    required Location pickupLocation,
    required Location dropoffLocation,
    required TripType tripType,
    required TransportDetails transportDetails,
    required double distance,
    required int estimatedDuration,
    required double fare,
  }) async {
    try {
      // Create trip document
      final trip = Trip(
        id: '',
        userId: userId,
        userName: userName,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        tripType: tripType,
        transportDetails: transportDetails,
        distance: distance,
        estimatedDuration: estimatedDuration,
        fare: fare,
        status: TripStatus.requested,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore.collection('trips').add(trip.toJson());
      
      // Update the trip with the generated ID
      await _firestore.collection('trips').doc(docRef.id).update({
        'id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  Future<double> calculateDistance(
    Location pickup,
    Location dropoff,
  ) async {
    // Simple distance calculation using haversine formula
    // In a real app, you would use Google Maps Distance Matrix API
    const double earthRadius = 6371.0; // Earth radius in kilometers
    
    final double dLat = _degreesToRadians(dropoff.latitude - pickup.latitude);
    final double dLon = _degreesToRadians(dropoff.longitude - pickup.longitude);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(pickup.latitude)) * 
        math.cos(_degreesToRadians(dropoff.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }

  Future<int> calculateEstimatedDuration(
    Location pickup,
    Location dropoff,
    double distance,
  ) async {
    // Simple estimation: 30 km/h average speed + 5 minutes buffer
    // In a real app, you would use Google Maps Directions API
    const double averageSpeed = 30.0; // km/h
    const int bufferMinutes = 5;
    
    final double hours = distance / averageSpeed;
    final int minutes = (hours * 60).round();
    
    return minutes + bufferMinutes;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}