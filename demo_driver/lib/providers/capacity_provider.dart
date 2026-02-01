import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/vehicle_capacity.dart';
import '../services/capacity_service.dart';

class CapacityProvider extends ChangeNotifier {
  final CapacityService _capacityService = CapacityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  VehicleCapacity? _currentCapacity;
  String? _driverId;
  StreamSubscription? _capacitySubscription;

  VehicleCapacity? get currentCapacity => _currentCapacity;
  String get capacityStatus => _currentCapacity != null 
      ? _capacityService.getCapacityStatus(_currentCapacity!) 
      : "Capacity not initialized";

  bool get isCapacityInitialized => _currentCapacity != null;

  bool get hasCapacitySetup => _currentCapacity != null &&
      _currentCapacity!.totalSeats > 0 &&
      _currentCapacity!.totalCargoKg > 0;

  bool hasAnyCapacity(VehicleCapacity capacity) {
    return _capacityService.hasAnyCapacity(capacity);
  }

  // Initialize driver capacity
  Future<void> initializeDriverCapacity(String driverId, int totalSeats, int totalCargoKg) async {
    _driverId = driverId;
    
    // Set initial capacity in Firestore
    final docRef = _firestore.collection('drivers').doc(driverId);
    
    final initialCapacity = VehicleCapacity.initial(totalSeats, totalCargoKg);
    
    await docRef.set({
      'vehicleCapacity': initialCapacity.toJson(),
      'onlineStatus': 'online',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    _currentCapacity = initialCapacity;
    notifyListeners();
    
    // Start listening for capacity updates
    await startListeningToCapacityUpdates();
  }

  // Start listening to real-time capacity updates
  Future<void> startListeningToCapacityUpdates() async {
    if (_driverId == null) return;
    
    _capacitySubscription = _firestore
        .collection('drivers')
        .doc(_driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final capacityData = data?['vehicleCapacity'];
        if (capacityData != null) {
          _currentCapacity = VehicleCapacity.fromJson(capacityData);
          notifyListeners();
        }
      }
    });
  }

  // Accept a booking request
  Future<bool> acceptBooking(BookingRequest request) async {
    if (_currentCapacity == null) {
      throw Exception("Capacity not initialized");
    }

    // Validate if booking can be accepted
    bool canAccept = _capacityService.canAcceptBooking(_currentCapacity!, request);
    if (!canAccept) {
      throw Exception("Cannot accept booking - insufficient capacity");
    }

    // Update capacity
    final updatedCapacity = _capacityService.updateCapacityAfterBooking(_currentCapacity!, request);
    
    // Update in Firestore
    if (_driverId != null) {
      await _firestore.collection('drivers').doc(_driverId!).set({
        'vehicleCapacity': updatedCapacity.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    _currentCapacity = updatedCapacity;
    notifyListeners();
    
    return true;
  }

  // Complete a booking (free up capacity)
  Future<bool> completeBooking(BookingRequest request) async {
    if (_currentCapacity == null) {
      throw Exception("Capacity not initialized");
    }

    // Update capacity after completion
    final updatedCapacity = _capacityService.updateCapacityAfterCompletion(_currentCapacity!, request);
    
    // Update in Firestore
    if (_driverId != null) {
      await _firestore.collection('drivers').doc(_driverId!).set({
        'vehicleCapacity': updatedCapacity.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    _currentCapacity = updatedCapacity;
    notifyListeners();
    
    return true;
  }

  // Validate if a booking can be accepted (without updating capacity)
  bool canAcceptBooking(BookingRequest request) {
    if (_currentCapacity == null) return false;
    return _capacityService.canAcceptBooking(_currentCapacity!, request);
  }

  // Get simulation of booking validation
  Map<String, dynamic> simulateBookingValidation(BookingRequest request) {
    if (_currentCapacity == null) {
      return {'canAccept': false, 'reason': "Capacity not initialized"};
    }
    return _capacityService.simulateBookingValidation(_currentCapacity!, request);
  }

  // Update driver online/offline status
  Future<void> updateOnlineStatus(String status) async {
    if (_driverId != null) {
      await _firestore.collection('drivers').doc(_driverId!).set({
        'onlineStatus': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get driver's current capacity for user app display
  Future<VehicleCapacity?> getDriverCapacity(String driverId) async {
    final docSnapshot = await _firestore.collection('drivers').doc(driverId).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final capacityData = data?['vehicleCapacity'];
      if (capacityData != null) {
        return VehicleCapacity.fromJson(capacityData);
      }
    }
    return null;
  }

  // Cancel subscription when provider is disposed
  @override
  void dispose() {
    _capacitySubscription?.cancel();
    super.dispose();
  }

  // Reset capacity (for testing or re-initialization)
  Future<void> resetCapacity(int totalSeats, int totalCargoKg) async {
    if (_driverId != null) {
      final resetCapacity = VehicleCapacity.initial(totalSeats, totalCargoKg);
      await _firestore.collection('drivers').doc(_driverId!).set({
        'vehicleCapacity': resetCapacity.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _currentCapacity = resetCapacity;
      notifyListeners();
    }
  }
}