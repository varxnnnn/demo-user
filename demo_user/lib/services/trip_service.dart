import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new trip request
  Future<String> createTripRequest({
    required String userId,
    required String userName,
    required String pickupLocation,
    required String dropoffLocation,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double fare,
  }) async {
    try {
      // Create a new trip document
      DocumentReference tripRef = await _firestore.collection('trips').add({
        'userId': userId,
        'userName': userName,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'fare': fare,
        'status': 'requested', // Initial status
        'createdAt': FieldValue.serverTimestamp(),
        'driverId': null, // Will be assigned when a driver accepts
        'driverName': null,
        'driverPhone': null,
        'vehicleNumber': null,
        'estimatedArrivalTime': null,
      });

      return tripRef.id;
    } catch (e) {
      print('Error creating trip request: $e');
      rethrow;
    }
  }

  // Get trip status updates
  Stream<Trip?> getTripUpdates(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Trip.fromJson({
          'id': snapshot.id,
          ...snapshot.data() as Map<String, dynamic>,
        });
      }
      return null;
    });
  }

  // Cancel trip request
  Future<void> cancelTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling trip: $e');
      rethrow;
    }
  }

  // Get user's trip history
  Future<List<Trip>> getUserTripHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20) // Limit to last 20 trips
          .get();

      return snapshot.docs
          .map((doc) => Trip.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error getting trip history: $e');
      return [];
    }
  }
}