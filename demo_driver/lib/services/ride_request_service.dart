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
    // Combine ride requests from rideRequests collection AND trips collection
    // This handles both new trips (with rideRequest) and old trips (without rideRequest)
    
    return _firestore
        .collection('rideRequests')
        .where('driverId', isEqualTo: null) // Only unassigned requests
        .snapshots()
        .asyncMap((snapshot) async {
          // Get ride requests from rideRequests collection
          var filteredDocs = snapshot.docs.where((doc) {
            String status = doc['status'] ?? '';
            return status == 'pending' || status == 'negotiating';
          }).toList();
          
          // Also get unassigned trips from trips collection
          final tripsSnapshot = await _firestore
              .collection('trips')
              .where('driverId', isEqualTo: null)
              .where('status', isEqualTo: 'requested')
              .get();
          
          // Convert trips to UserRideRequest format
          final allRequests = <Map<String, dynamic>>[];
          
          // Add ride requests from rideRequests collection
          for (var doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            allRequests.add(data);
          }
          
          // Add trips from trips collection that don't have a corresponding rideRequest
          for (var doc in tripsSnapshot.docs) {
            final tripId = doc.id;
            // Check if this trip already has a rideRequest entry
            final rideReqExists = filteredDocs.any((d) => d.id == tripId);
            
            if (!rideReqExists) {
              final tripData = doc.data() as Map<String, dynamic>;
              // Convert trip to rideRequest format
              final pickupLocData = tripData['pickupLocation'];
              final dropoffLocData = tripData['dropoffLocation'];
              
              double pickupLat = 0.0;
              double pickupLng = 0.0;
              double dropoffLat = 0.0;
              double dropoffLng = 0.0;
              String pickupAddr = '';
              String dropoffAddr = '';
              
              if (pickupLocData is Map<String, dynamic>) {
                pickupLat = (pickupLocData['latitude'] as num?)?.toDouble() ?? 0.0;
                pickupLng = (pickupLocData['longitude'] as num?)?.toDouble() ?? 0.0;
                pickupAddr = pickupLocData['formattedAddress']?.toString() ?? '';
              }
              
              if (dropoffLocData is Map<String, dynamic>) {
                dropoffLat = (dropoffLocData['latitude'] as num?)?.toDouble() ?? 0.0;
                dropoffLng = (dropoffLocData['longitude'] as num?)?.toDouble() ?? 0.0;
                dropoffAddr = dropoffLocData['formattedAddress']?.toString() ?? '';
              }
              
              final rideRequest = {
                'id': tripId,
                'userId': tripData['userId'],
                'userName': tripData['userName'],
                'userRating': 4.5, // Default rating
                'pickupLocation': pickupAddr,
                'dropoffLocation': dropoffAddr,
                'pickupLat': pickupLat,
                'pickupLng': pickupLng,
                'dropoffLat': dropoffLat,
                'dropoffLng': dropoffLng,
                'distance': (tripData['distance'] as num?)?.toDouble() ?? 0.0,
                'offeredPrice': (tripData['fare'] as num?)?.toDouble() ?? 0.0,
                'urgency': 'medium',
                'requestedAt': tripData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                'status': 'pending',
                'driverId': null,
                'negotiatedPrice': null,
              };
              allRequests.add(rideRequest);
            }
          }
          
          // Sort by requestedAt in descending order
          allRequests.sort((a, b) {
            var timeA = a['requestedAt'] ?? 0;
            var timeB = b['requestedAt'] ?? 0;
            // Convert to int if it's a Timestamp
            if (timeA is Timestamp) timeA = timeA.millisecondsSinceEpoch;
            if (timeB is Timestamp) timeB = timeB.millisecondsSinceEpoch;
            return timeB.compareTo(timeA); // Descending order
          });
          
          return allRequests.map((data) {
            try {
              return UserRideRequest.fromJson(data);
            } catch (e) {
              print('Error parsing ride request: $e');
              print('Data: $data');
              return null;
            }
          }).whereType<UserRideRequest>().toList();
        });
  }

  // Accept a ride request
  Future<void> acceptRideRequest(String requestId, String driverId, String driverName) async {
    try {
      // Get the current driver's information from the drivers collection
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
      final driverData = driverDoc.data();
      
      // Prepare driver information
      final driverInfo = {
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverData?['phone'] ?? '',
        'vehicleNumber': driverData?['vehicleNumber'] ?? '',
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      };
      
      // Update the rideRequests collection
      await _firestore.collection('rideRequests').doc(requestId).update(driverInfo);
      
      // Also update the main trips collection to ensure consistency
      await _firestore.collection('trips').doc(requestId).update(driverInfo);
    } catch (e) {
      print('Error accepting ride request: $e');
      rethrow;
    }
  }

  // Reject a ride request
  Future<void> rejectRideRequest(String requestId) async {
    try {
      // First try to update the rideRequests collection
      try {
        await _firestore.collection('rideRequests').doc(requestId).update({
          'status': 'rejected',
          'rejectedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        // If rideRequest doesn't exist, it's an old trip, update the trips collection instead
        print('RideRequest not found, updating trips collection: $e');
        await _firestore.collection('trips').doc(requestId).update({
          'status': 'rejected',
          'rejectedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
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
            final data = doc.data();
            data['id'] = doc.id;
            return UserRideRequest.fromJson(data);
          }).toList();
        });
  }
}