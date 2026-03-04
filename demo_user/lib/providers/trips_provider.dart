import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../services/trip_creation_service.dart';

class TripsProvider with ChangeNotifier {
  final TripCreationService _tripCreationService = TripCreationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch trip history for a specific user
  Future<void> fetchUserTrips(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Fetching trips for user: $userId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .get();

      print('Got ${snapshot.docs.length} trips from Firestore');

      _trips = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing trip: ${doc.id}');
          print('Trip data keys: ${data.keys}');
          
          final trip = Trip.fromJson({
            'id': doc.id,
            ...data,
          });
          _trips.add(trip);
        } catch (e) {
          print('Error parsing trip ${doc.id}: $e');
          print('Document data: ${doc.data()}');
        }
      }

      // Sort by createdAt in descending order
      _trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Successfully loaded ${_trips.length} trips');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error fetching trips: $e');
      print('Stack trace: $stackTrace');
      _error = 'Failed to load trip history: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create and save a new trip
  Future<String?> createTrip({
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
      final tripId = await _tripCreationService.createTrip(
        userId: userId,
        userName: userName,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        tripType: tripType,
        transportDetails: transportDetails,
        distance: distance,
        estimatedDuration: estimatedDuration,
        fare: fare,
      );

      // Add the new trip to the list
      final newTrip = Trip(
        id: tripId,
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

      _trips.insert(0, newTrip);
      _error = null;
      notifyListeners();

      return tripId;
    } catch (e) {
      _error = 'Failed to create trip: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Empty the trips list
  void clearTrips() {
    _trips = [];
    notifyListeners();
  }
}
