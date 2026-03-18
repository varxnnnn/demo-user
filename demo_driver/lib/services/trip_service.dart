import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/user_ride_request.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new trip
  Future<void> createTrip(Trip trip) async {
    try {
      await _firestore.collection('trips').doc(trip.id).set(trip.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get trips for a driver
  Future<List<Trip>> getDriverTrips(String driverId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Trip.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get nearby trip requests (real implementation)
  Stream<List<Trip>> getNearbyTripRequests(String driverId) {
    return _firestore
        .collection('trips')
        .where('status', isEqualTo: 'requested')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Trip.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    });
  }
  
  // Get nearby trip requests (simulated for testing)
  Future<List<Trip>> getNearbyTripRequestsList(String driverId) async {
    // This is a simulated function. In a real app, this would use geolocation
    // to find nearby trip requests
    return [
      Trip(
        id: 'trip1',
        userId: 'user1',
        userName: 'John Doe',
        pickupLocation: 'Central Market',
        dropoffLocation: 'City Mall',
        pickupLat: 17.3850,
        pickupLng: 78.4867,
        dropoffLat: 17.4000,
        dropoffLng: 78.5000,
        fare: 150.0,
        status: 'requested',
        createdAt: DateTime.now(),
      ),
      Trip(
        id: 'trip2',
        userId: 'user2',
        userName: 'Jane Smith',
        pickupLocation: 'Railway Station',
        dropoffLocation: 'Airport',
        pickupLat: 17.3950,
        pickupLng: 78.4967,
        dropoffLat: 17.4100,
        dropoffLng: 78.5100,
        fare: 120.0,
        status: 'requested',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  // Update trip status
  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      Map<String, dynamic> updateData = {'status': status};
      
      switch (status) {
        case 'accepted':
          updateData['acceptedAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case 'driver_arrived':
          updateData['driverArrivedAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case 'in_progress':
          updateData['startedAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case 'cancelled':
          updateData['cancelledAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case 'completed':
          updateData['completedAt'] = DateTime.now().millisecondsSinceEpoch;
          break;
      }
      
      await _firestore.collection('trips').doc(tripId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Accept a trip request
  Future<void> acceptTrip(String tripId, String driverId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'driverId': driverId,
        'status': 'accepted',
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get ride requests for a driver (new method)
  Stream<List<UserRideRequest>> getRideRequestsForDriver(String driverId) {
    return _firestore
        .collection('rideRequests')
        .where('status', whereIn: ['pending', 'negotiating'])
        .orderBy('requestedAt', descending: true)
        .snapshots() // Remove limit for better real-time experience
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID
            return UserRideRequest.fromJson(data);
          }).toList();
        });
  }

  // Accept a ride request (new method)
  Future<void> acceptRideRequest(String requestId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'accepted',
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reject a ride request (new method)
  Future<void> rejectRideRequest(String requestId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Cancel a trip
  Future<void> cancelTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'cancelled',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get active pooled ride for driver
  Future<Map<String, dynamic>?> getActivePooledRideForDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('pooledRideGroups')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      print('Error getting active pool: $e');
      return null;
    }
  }

  // Get pools for driver (stream of active pools)
  Stream<List<Map<String, dynamic>>> getDriverPoolsStream(String driverId) {
    return _firestore
        .collection('pooledRideGroups')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get trips in a pooling group
  Future<List<Trip>> getTripsInPool(String poolingKey) async {
    try {
      final poolDoc = await _firestore
          .collection('pooledRideGroups')
          .doc(poolingKey)
          .get();

      if (!poolDoc.exists) return [];

      final tripIds = List<String>.from(poolDoc.data()?['tripIds'] ?? []);
      final trips = <Trip>[];

      for (final tripId in tripIds) {
        final tripDoc = await _firestore.collection('trips').doc(tripId).get();
        if (tripDoc.exists) {
          trips.add(Trip.fromJson({'id': tripId, ...tripDoc.data() as Map<String, dynamic>}));
        }
      }

      return trips;
    } catch (e) {
      print('Error getting trips in pool: $e');
      return [];
    }
  }

  // Update trip with pooling info
  Future<void> updateTripPoolingInfo({
    required String tripId,
    required String poolingKey,
    required double pooledFare,
  }) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'poolingKey': poolingKey,
        'isPooled': true,
        'pooledFare': pooledFare,
      });
    } catch (e) {
      rethrow;
    }
  }
}