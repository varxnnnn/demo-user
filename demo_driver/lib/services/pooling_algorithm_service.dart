import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_completion.dart';

class PoolingAlgorithmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find compatible trips for pooling based on route similarity
  Future<List<String>> findCompatibleTripsForPooling({
    required String tripId,
    required String driverId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    double maxDeviationKm = 2.0, // Max deviation from direct route
  }) async {
    try {
      // Get all pending trips that match criteria
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'requested')
          .where('driverId', isEqualTo: '') // Not yet assigned
          .limit(10)
          .get();

      final compatibleTrips = <String>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final otherTripId = doc.id;

        // Skip same trip
        if (otherTripId == tripId) continue;

        // Get other trip coordinates
        final otherPickupLat = (data['pickupLat'] as num?)?.toDouble() ?? 0;
        final otherPickupLng = (data['pickupLng'] as num?)?.toDouble() ?? 0;
        final otherDropoffLat = (data['dropoffLat'] as num?)?.toDouble() ?? 0;
        final otherDropoffLng = (data['dropoffLng'] as num?)?.toDouble() ?? 0;

        // Calculate route compatibility
        final similarity = calculateRouteSimilarity(
          pickupLat,
          pickupLng,
          dropoffLat,
          dropoffLng,
          otherPickupLat,
          otherPickupLng,
          otherDropoffLat,
          otherDropoffLng,
        );

        // If similarity is high, consider for pooling
        if (similarity > 0.7) {
          // Check if pickup/dropoff don't deviate too much from main route
          final deviationKm = _calculateRouteDeviation(
            mainPickupLat: pickupLat,
            mainPickupLng: pickupLng,
            mainDropoffLat: dropoffLat,
            mainDropoffLng: dropoffLng,
            otherLat: otherPickupLat,
            otherLng: otherPickupLng,
          );

          if (deviationKm <= maxDeviationKm) {
            compatibleTrips.add(otherTripId);
          }
        }
      }

      return compatibleTrips;
    } catch (e) {
      print('Error finding compatible trips: $e');
      return [];
    }
  }

  /// Calculate route similarity (0-1) based on overlapping pickup/dropoff areas
  /// Public version for external use
  double calculateRouteSimilarity(
    double pickup1Lat,
    double pickup1Lng,
    double dropoff1Lat,
    double dropoff1Lng,
    double pickup2Lat,
    double pickup2Lng,
    double dropoff2Lat,
    double dropoff2Lng,
  ) {
    // Distance between pickups (should be close)
    final pickupDistance = _haversineDistance(
      pickup1Lat,
      pickup1Lng,
      pickup2Lat,
      pickup2Lng,
    );

    // Distance between dropoffs (should be close)
    final dropoffDistance = _haversineDistance(
      dropoff1Lat,
      dropoff1Lng,
      dropoff2Lat,
      dropoff2Lng,
    );

    // Score based on proximity (closer = higher score)
    // Max acceptable distance: 2 km each
    final pickupScore = max(0, (2.0 - pickupDistance) / 2.0);
    final dropoffScore = max(0, (2.0 - dropoffDistance) / 2.0);

    // Average the scores
    return (pickupScore + dropoffScore) / 2.0;
  }

  /// Calculate deviation of a point from the main route
  double _calculateRouteDeviation({
    required double mainPickupLat,
    required double mainPickupLng,
    required double mainDropoffLat,
    required double mainDropoffLng,
    required double otherLat,
    required double otherLng,
  }) {
    // Calculate distance from other point to the main route's pickup
    return _haversineDistance(
      mainPickupLat,
      mainPickupLng,
      otherLat,
      otherLng,
    );
  }

  /// Haversine formula to calculate distance between two coordinates (in km)
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Create pooled ride group and calculate fares
  Future<PooledRideGroup?> createPooledRideGroup({
    required String driverId,
    required List<String> tripIds,
    required Map<String, double> baseFares, // tripId -> baseFare
    double poolDiscount = 0.20, // 20% discount for pooling
  }) async {
    try {
      final poolingKey = 'POOL_${DateTime.now().millisecondsSinceEpoch}';
      final userIds = <String>[];
      final pickupOrder = <String>[];
      final dropoffOrder = <String>[];
      final individualFares = <String, double>{};

      // Retrieve trip data and determine order
      for (final tripId in tripIds) {
        final tripDoc = await _firestore.collection('trips').doc(tripId).get();
        final data = tripDoc.data() ?? {};
        final userId = data['userId'] as String?;

        if (userId != null) {
          userIds.add(userId);
          pickupOrder.add(userId); // Will optimize this
          dropoffOrder.add(userId); // Will optimize this

          // Calculate pooled fare
          final baseFare = baseFares[tripId] ?? 100.0;
          final pooledFare = baseFare * (1 - poolDiscount);
          individualFares[userId] = pooledFare;
        }
      }

      // Optimize pickup order (based on proximity to driver start location)
      pickupOrder.sort();

      // Reverse dropoff order (LIFO - last picked first dropped)
      dropoffOrder.sort((a, b) => b.compareTo(a));

      final poolGroup = PooledRideGroup(
        poolingKey: poolingKey,
        tripIds: tripIds,
        userIds: userIds,
        driverId: driverId,
        baseFarePerRide: baseFares.values.reduce((a, b) => a + b) / baseFares.length,
        poolDiscount: poolDiscount,
        individualFares: individualFares,
        pickupOrder: pickupOrder,
        dropoffOrder: dropoffOrder,
        createdAt: DateTime.now(),
      );

      // Save pooled ride group to Firestore
      await _firestore.collection('pooledRideGroups').doc(poolingKey).set(
        poolGroup.toJson(),
      );

      // Update all trips with pooling info
      for (final tripId in tripIds) {
        await _firestore.collection('trips').doc(tripId).update({
          'poolingKey': poolingKey,
          'isPooled': true,
          'driverId': driverId,
          'status': 'accepted',
        });
      }

      return poolGroup;
    } catch (e) {
      print('Error creating pooled ride group: $e');
      return null;
    }
  }

  /// Get active pooled ride group for driver
  Future<PooledRideGroup?> getActivePoolForDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('pooledRideGroups')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PooledRideGroup.fromJson(snapshot.docs.first.data());
    } catch (e) {
      print('Error getting active pool: $e');
      return null;
    }
  }

  /// Update pickup order after user confirmation
  Future<void> updatePickupOrder({
    required String poolingKey,
    required List<String> newOrder,
  }) async {
    try {
      await _firestore.collection('pooledRideGroups').doc(poolingKey).update({
        'pickupOrder': newOrder,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating pickup order: $e');
      rethrow;
    }
  }

  /// Mark user as picked up in pool
  Future<void> markUserPickedUp({
    required String poolingKey,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('pooledRideGroups')
          .doc(poolingKey)
          .collection('pickupStatus')
          .doc(userId)
          .set({
        'userId': userId,
        'pickedUpAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking user picked up: $e');
      rethrow;
    }
  }

  /// Mark user as dropped off in pool
  Future<void> markUserDroppedOff({
    required String poolingKey,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('pooledRideGroups')
          .doc(poolingKey)
          .collection('dropoffStatus')
          .doc(userId)
          .set({
        'userId': userId,
        'droppedOffAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking user dropped off: $e');
      rethrow;
    }
  }

  /// Complete pooled ride group
  Future<void> completePooledRide({
    required String poolingKey,
  }) async {
    try {
      await _firestore.collection('pooledRideGroups').doc(poolingKey).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing pooled ride: $e');
      rethrow;
    }
  }
}
