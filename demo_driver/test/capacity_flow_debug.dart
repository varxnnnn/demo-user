import 'package:flutter_test/flutter_test.dart';
import 'package:demo_driver/models/vehicle_capacity.dart';
import 'package:demo_driver/services/capacity_service.dart';

void main() {
  group('Capacity Flow Debug with Fake Data', () {
    final capacityService = CapacityService();
    
    // Initial State: 4 seats, 50kg cargo
    final initialCapacity = VehicleCapacity(
      totalSeats: 4,
      totalCargoKg: 50,
      availableSeats: 4,
      availableCargoKg: 50,
    );

    test('Flow 1: Passenger Ride Acceptance and Completion', () {
      print('\n--- Flow 1: Passenger Ride (2 people) ---');
      print('Initial Capacity: ${initialCapacity.availableSeats} seats, ${initialCapacity.availableCargoKg}kg cargo');

      // 1. Accept Passenger Ride
      final passengerRequest = BookingRequest(
        id: 'trip_123',
        type: 'passenger',
        passengerCount: 2,
        pickupLocation: 'Point A',
        destination: 'Point B',
        timestamp: DateTime.now(),
      );

      final occupiedCapacity = capacityService.updateCapacityAfterBooking(initialCapacity, passengerRequest);
      print('After Acceptance (2 passengers): ${occupiedCapacity.availableSeats} seats, ${occupiedCapacity.availableCargoKg}kg cargo');
      
      expect(occupiedCapacity.availableSeats, 2);
      expect(occupiedCapacity.availableCargoKg, 50);

      // 2. Complete Passenger Ride
      final restoredCapacity = capacityService.updateCapacityAfterCompletion(occupiedCapacity, passengerRequest);
      print('After Completion: ${restoredCapacity.availableSeats} seats, ${restoredCapacity.availableCargoKg}kg cargo');
      
      expect(restoredCapacity.availableSeats, 4);
      expect(restoredCapacity.availableCargoKg, 50);
    });

    test('Flow 2: Cargo Ride Acceptance and Completion', () {
      print('\n--- Flow 2: Cargo Ride (20kg) ---');
      print('Initial Capacity: ${initialCapacity.availableSeats} seats, ${initialCapacity.availableCargoKg}kg cargo');

      // 1. Accept Cargo Ride
      final cargoRequest = BookingRequest(
        id: 'trip_456',
        type: 'cargo',
        cargoWeight: 20.0,
        pickupLocation: 'Point C',
        destination: 'Point D',
        timestamp: DateTime.now(),
      );

      final occupiedCapacity = capacityService.updateCapacityAfterBooking(initialCapacity, cargoRequest);
      print('After Acceptance (20kg cargo): ${occupiedCapacity.availableSeats} seats, ${occupiedCapacity.availableCargoKg}kg cargo');
      
      expect(occupiedCapacity.availableSeats, 4);
      expect(occupiedCapacity.availableCargoKg, 30);

      // 2. Complete Cargo Ride
      final restoredCapacity = capacityService.updateCapacityAfterCompletion(occupiedCapacity, cargoRequest);
      print('After Completion: ${restoredCapacity.availableSeats} seats, ${restoredCapacity.availableCargoKg}kg cargo');
      
      expect(restoredCapacity.availableSeats, 4);
      expect(restoredCapacity.availableCargoKg, 50);
    });
    
    test('Flow 3: Mixed Format Handling (Nested Data Simulation)', () {
      print('\n--- Flow 3: Nested Data Simulation (Simulating User App Format) ---');
      
      // Simulate tripData from Firestore (Nested format)
      final tripData = {
        'tripType': 'objectTransport',
        'transportDetails': {
          'weight': 15.0,
        },
        'pickupLocation': {'formattedAddress': 'Source'},
        'dropoffLocation': {'formattedAddress': 'Dest'}
      };

      // Extract logic we added to RideRequestService
      String type = tripData['tripType'] == 'objectTransport' ? 'cargo' : 'passenger';
      double cargoWeight = (tripData['transportDetails'] as Map<String, dynamic>)['weight'] as double;
      
      final nestedCargoRequest = BookingRequest(
        id: 'trip_789',
        type: type,
        cargoWeight: cargoWeight,
        pickupLocation: 'Source',
        destination: 'Dest',
        timestamp: DateTime.now(),
      );

      final occupiedCapacity = capacityService.updateCapacityAfterBooking(initialCapacity, nestedCargoRequest);
      print('After Acceptance (Nested 15kg cargo): ${occupiedCapacity.availableSeats} seats, ${occupiedCapacity.availableCargoKg}kg cargo');
      
      expect(occupiedCapacity.availableSeats, 4);
      expect(occupiedCapacity.availableCargoKg, 35);
      
      final restoredCapacity = capacityService.updateCapacityAfterCompletion(occupiedCapacity, nestedCargoRequest);
      print('After Completion: ${restoredCapacity.availableSeats} seats, ${restoredCapacity.availableCargoKg}kg cargo');
      
      expect(restoredCapacity.availableSeats, 4);
      expect(restoredCapacity.availableCargoKg, 50);
    });
  });
}
