import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_completion.dart';

class RideCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Complete a ride and record completion details
  Future<void> completeRide({
    required String tripId,
    required RideCompletionDetails completionDetails,
  }) async {
    try {
      // Update trip document with completion data
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completion': completionDetails.toJson(),
      });

      // Record receipt
      await _recordReceipt(tripId, completionDetails);
    } catch (e) {
      print('Error completing ride: $e');
      rethrow;
    }
  }

  /// Record trip receipt for both parties
  Future<void> _recordReceipt(
    String tripId,
    RideCompletionDetails details,
  ) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('receipts')
          .add({
        'tripId': tripId,
        'driverId': details.driverId,
        'userId': details.userId,
        'totalFare': details.totalFare,
        'paymentMethod': details.paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording receipt: $e');
    }
  }

  /// Submit a rating for completed ride
  Future<void> submitRating({
    required String tripId,
    required String ratedBy, // 'driver' or 'user'
    required String ratedUserId,
    required double rating,
    required String review,
    List<String> tags = const [],
  }) async {
    try {
      final ratingId = '${tripId}_${ratedBy}_${DateTime.now().millisecondsSinceEpoch}';

      // Store rating
      await _firestore.collection('ratings').doc(ratingId).set({
        'id': ratingId,
        'tripId': tripId,
        'ratedBy': ratedBy,
        'ratedUserId': ratedUserId,
        'rating': rating,
        'review': review,
        'tags': tags,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user/driver average rating
      if (ratedBy == 'user') {
        await _updateDriverRating(ratedUserId, rating);
      } else {
        await _updateUserRating(ratedUserId, rating);
      }
    } catch (e) {
      print('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Update driver's average rating
  Future<void> _updateDriverRating(String driverId, double newRating) async {
    try {
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();

      if (driverDoc.exists) {
        final data = driverDoc.data() ?? {};
        final currentRating = (data['rating'] ?? 4.5).toDouble();
        final rideCount = (data['completedRides'] ?? 0).toInt();
        
        // Calculate new average
        final newAverage = ((currentRating * rideCount) + newRating) / (rideCount + 1);

        await _firestore.collection('drivers').doc(driverId).update({
          'rating': newAverage,
          'completedRides': rideCount + 1,
          'lastRated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }

  /// Update user's average rating (by drivers)
  Future<void> _updateUserRating(String userId, double newRating) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final currentRating = (data['rating'] ?? 4.5).toDouble();
        final rideCount = (data['completedRides'] ?? 0).toInt();
        
        // Calculate new average
        final newAverage = ((currentRating * rideCount) + newRating) / (rideCount + 1);

        await _firestore.collection('users').doc(userId).update({
          'rating': newAverage,
          'completedRides': rideCount + 1,
          'lastRated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  /// Get ratings for a user/driver
  Future<List<Rating>> getUserRatings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Rating.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting ratings: $e');
      return [];
    }
  }

  /// Check if user has already rated this trip
  Future<bool> hasUserRatedTrip(String tripId, String ratedBy) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('tripId', isEqualTo: tripId)
          .where('ratedBy', isEqualTo: ratedBy)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking rating: $e');
      return false;
    }
  }
}
