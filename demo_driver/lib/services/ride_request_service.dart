import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_ride_request.dart';

class RideRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new ride request (for users)
  Future<void> createRideRequest(UserRideRequest request) async {
    try {
      await _firestore.collection('rideRequests').doc(request.id).set(request.toJson());
      print('Ride request created: ${request.id}');
    } catch (e) {
      print('Error creating ride request: $e');
      rethrow;
    }
  }

  // Get nearby online drivers for user (like Rapido)
  Future<List<Map<String, dynamic>>> getNearbyDrivers(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .where('onlineStatus', isEqualTo: 'online')
          .where('isVerified', isEqualTo: true)
          .limit(20) // Limit to nearby 20 drivers
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting nearby drivers: $e');
      return [];
    }
  }

  // Get ride requests for a specific driver
  Stream<List<UserRideRequest>> getRideRequestsForDriver(String driverId) {
    return _firestore
        .collection('rideRequests')
        .where('driverId', isEqualTo: null) // Only unassigned requests
        .where('status', whereIn: ['pending', 'negotiating'])
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return UserRideRequest.fromJson(data);
          }).toList();
        });
  }

  // Accept a ride request
  Future<void> acceptRideRequest(String requestId, String driverId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'driverId': driverId,
        'status': 'accepted',
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error accepting ride request: $e');
      rethrow;
    }
  }

  // Reject a ride request
  Future<void> rejectRideRequest(String requestId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error rejecting ride request: $e');
      rethrow;
    }
  }

  // Negotiate price for a ride
  Future<void> negotiateRideRequest(String requestId, double offeredPrice) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'negotiatedPrice': offeredPrice,
        'status': 'negotiating',
        'negotiatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error negotiating ride request: $e');
      rethrow;
    }
  }

  // Complete ride (after driver completes the trip)
  Future<void> completeRideRequest(String requestId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'completed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error completing ride: $e');
      rethrow;
    }
  }

  // Cancel ride
  Future<void> cancelRideRequest(String requestId) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error cancelling ride: $e');
      rethrow;
    }
  }

  // Add chat message to ride request
  Future<void> addChatMessage(String requestId, Map<String, dynamic> message) async {
    try {
      await _firestore.collection('rideRequests').doc(requestId).update({
        'lastMessage': message,
        'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error adding chat message: $e');
      rethrow;
    }
  }

  // Get user's ride requests
  Stream<List<UserRideRequest>> getUserRideRequests(String userId) {
    return _firestore
        .collection('rideRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return UserRideRequest.fromJson(data);
          }).toList();
        });
  }
}