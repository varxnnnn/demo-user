import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_completion.dart';
import '../models/vehicle_capacity.dart';
import 'capacity_service.dart';

class RideCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CapacityService _capacityService = CapacityService();

  /// Complete a ride and record completion details
  Future<void> completeRide({
    required String tripId,
    required RideCompletionDetails completionDetails,
  }) async {
    try {
      // 1. Update trip document with completion data
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completion': completionDetails.toJson(),
      });

      // 2. Free up capacity for the driver
      await _freeUpCapacity(completionDetails.driverId, tripId);

      // 3. Record receipt
      await _recordReceipt(tripId, completionDetails);

      // 4. Record earnings and update driver wallet
      await _recordEarning(completionDetails);

      // 5. Add to driver's completed trips history
      await _recordCompletedTrip(completionDetails);
    } catch (e) {
      print('Error completing ride: $e');
      rethrow;
    }
  }

  /// Free up capacity after a ride is completed
  Future<void> _freeUpCapacity(String driverId, String tripId) async {
    try {
      print('[CapacityRestoration] Starting for driverId=$driverId, tripId=$tripId');
      
      // Get the trip to find what capacity was used
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        print('[CapacityRestoration] Trip document not found');
        return;
      }
      
      final tripData = tripDoc.data() as Map<String, dynamic>;
       
       // Get booking details from the trip
       // Support both formats: direct fields and nested transportDetails
       String type = 'passenger';
       if (tripData['tripType'] == 'objectTransport' || tripData['type'] == 'cargo') {
         type = 'cargo';
       }

       int passengerCount = 0;
       double cargoWeight = 0.0;

       if (type == 'passenger') {
         passengerCount = (tripData['passengerCount'] as num?)?.toInt() ?? 
                         (tripData['transportDetails']?['numberOfPassengers'] as num?)?.toInt() ?? 1;
       } else {
         cargoWeight = (tripData['cargoWeight'] as num?)?.toDouble() ?? 
                      (tripData['transportDetails']?['weight'] as num?)?.toDouble() ?? 0.0;
       }
       
       // Create a BookingRequest representation to use with CapacityService
       final bookingRequest = BookingRequest(
         id: tripId,
         type: type,
         passengerCount: passengerCount,
         cargoWeight: cargoWeight,
         pickupLocation: tripData['pickupLocation'] is Map 
             ? (tripData['pickupLocation']['formattedAddress'] ?? '') 
             : (tripData['pickupLocation'] ?? ''),
         destination: tripData['dropoffLocation'] is Map 
             ? (tripData['dropoffLocation']['formattedAddress'] ?? '') 
             : (tripData['dropoffLocation'] ?? ''),
         timestamp: DateTime.now(),
       );

      // Get current driver capacity
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
      if (!driverDoc.exists) {
        print('[CapacityRestoration] Driver document not found');
        return;
      }
      
      final driverData = driverDoc.data() as Map<String, dynamic>;
      final capacityData = driverData['vehicleCapacity'];
      
      if (capacityData != null) {
        final currentCapacity = VehicleCapacity.fromJson(capacityData as Map<String, dynamic>);
        
        // Use CapacityService to calculate new capacity
        final updatedCapacity = _capacityService.updateCapacityAfterCompletion(
          currentCapacity, 
          bookingRequest
        );
        
        print('[CapacityRestoration] Updating capacity: \${currentCapacity.availableSeats} -> \${updatedCapacity.availableSeats} seats');

        // Update driver document
        await _firestore.collection('drivers').doc(driverId).update({
          'vehicleCapacity': updatedCapacity.toJson(),
        });
        
        // Also update the vehicle document if it exists
        final vehicleSnapshot = await _firestore
            .collection('vehicles')
            .where('driverId', isEqualTo: driverId)
            .limit(1)
            .get();
            
        if (vehicleSnapshot.docs.isNotEmpty) {
          final vehicleId = vehicleSnapshot.docs.first.id;
          await _firestore.collection('vehicles').doc(vehicleId).update({
            'vehicleCapacity': updatedCapacity.toJson(),
          });
        }
      }
      
      // Remove from activeTrips sub-collection
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('activeTrips')
          .doc(tripId)
          .delete();
          
      print('[CapacityRestoration] Successfully completed');
    } catch (e) {
      print('[CapacityRestoration] Error: $e');
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

  /// Record driver earning and update wallet balance
  Future<void> _recordEarning(RideCompletionDetails details) async {
    try {
      final driverId = details.driverId;
      final amount = details.totalFare;

      // 1. Add to driver's earnings sub-collection
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('earnings')
          .add({
        'tripId': details.tripId,
        'amount': amount,
        'paymentMethod': details.paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update driver's total wallet balance
      await _firestore.collection('drivers').doc(driverId).update({
        'wallet': FieldValue.increment(amount),
        'lastEarningsUpdate': FieldValue.serverTimestamp(),
      });
      
      print('[Earnings] Recorded ₹$amount for driver $driverId');
    } catch (e) {
      print('Error recording earning: $e');
    }
  }

  /// Record completed trip in driver's history
  Future<void> _recordCompletedTrip(RideCompletionDetails details) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(details.tripId).get();
      if (!tripDoc.exists) return;
      
      final tripData = tripDoc.data() as Map<String, dynamic>;
      
      // Add to driver's completedTrips sub-collection
      await _firestore
          .collection('drivers')
          .doc(details.driverId)
          .collection('completedTrips')
          .doc(details.tripId)
          .set({
        ...tripData,
        'status': 'completed',
        'completedAt': details.completedAt.millisecondsSinceEpoch,
        'fare': details.totalFare, // Use final fare from completion details
      });
      
      print('[History] Added trip \${details.tripId} to driver history');
    } catch (e) {
      print('Error recording completed trip: $e');
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
