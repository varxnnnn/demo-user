import '../lib/models/vehicle_capacity.dart';
import '../lib/services/capacity_service.dart';

void main() {
  // Create a demo vehicle capacity
  VehicleCapacity currentCapacity = VehicleCapacity.initial(4, 10); // 4 seats, 10 kg cargo
  print('Initial capacity: ${currentCapacity.toString()}');
  
  // Create a capacity service instance
  final capacityService = CapacityService();
  
  // Example 1: Passenger booking (2 people)
  print('\n--- Example 1: Passenger booking (2 people) ---');
  final passengerBooking = BookingRequest(
    id: 'booking1',
    type: 'passenger',
    passengerCount: 2,
    cargoWeight: 0.0,
    canUseSeats: false,
    cargoType: 'parcel',
    pickupLocation: 'Home',
    destination: 'Office',
    timestamp: DateTime.now(),
  );
  
  bool canAccept = capacityService.canAcceptBooking(currentCapacity, passengerBooking);
  print('Can accept passenger booking: $canAccept');
  
  if (canAccept) {
    currentCapacity = capacityService.updateCapacityAfterBooking(currentCapacity, passengerBooking);
    print('Updated capacity after passenger booking: ${currentCapacity.toString()}');
  }
  
  // Example 2: Cargo booking (5 kg)
  print('\n--- Example 2: Cargo booking (5 kg) ---');
  final cargoBooking = BookingRequest(
    id: 'booking2',
    type: 'cargo',
    passengerCount: 0,
    cargoWeight: 5.0,
    canUseSeats: false,
    cargoType: 'parcel',
    pickupLocation: 'Store',
    destination: 'Home',
    timestamp: DateTime.now(),
  );
  
  bool canAcceptCargo = capacityService.canAcceptBooking(currentCapacity, cargoBooking);
  print('Can accept cargo booking: $canAcceptCargo');
  
  if (canAcceptCargo) {
    currentCapacity = capacityService.updateCapacityAfterBooking(currentCapacity, cargoBooking);
    print('Updated capacity after cargo booking: ${currentCapacity.toString()}');
  }
  
  // Example 3: Document booking (no space consumption)
  print('\n--- Example 3: Document booking (no space consumption) ---');
  final documentBooking = BookingRequest(
    id: 'booking3',
    type: 'cargo',
    passengerCount: 0,
    cargoWeight: 0.0,
    canUseSeats: false,
    cargoType: 'document',
    pickupLocation: 'Office',
    destination: 'Court',
    timestamp: DateTime.now(),
  );
  
  bool canAcceptDoc = capacityService.canAcceptBooking(currentCapacity, documentBooking);
  print('Can accept document booking: $canAcceptDoc');
  
  if (canAcceptDoc) {
    currentCapacity = capacityService.updateCapacityAfterBooking(currentCapacity, documentBooking);
    print('Updated capacity after document booking: ${currentCapacity.toString()}');
  }
  
  // Example 4: Cargo booking that exceeds space but can use seats
  print('\n--- Example 4: Cargo booking with seat usage ---');
  final heavyCargoBooking = BookingRequest(
    id: 'booking4',
    type: 'cargo',
    passengerCount: 0,
    cargoWeight: 8.0,
    canUseSeats: true,
    cargoType: 'luggage',
    pickupLocation: 'Airport',
    destination: 'Hotel',
    timestamp: DateTime.now(),
  );
  
  bool canAcceptHeavy = capacityService.canAcceptBooking(currentCapacity, heavyCargoBooking);
  print('Can accept heavy cargo booking: $canAcceptHeavy');
  
  if (canAcceptHeavy) {
    currentCapacity = capacityService.updateCapacityAfterBooking(currentCapacity, heavyCargoBooking);
    print('Updated capacity after heavy cargo booking: ${currentCapacity.toString()}');
  }
  
  // Example 5: Check capacity status
  print('\n--- Capacity Status ---');
  print('Capacity status: ${capacityService.getCapacityStatus(currentCapacity)}');
  print('Has any capacity: ${capacityService.hasAnyCapacity(currentCapacity)}');
  print('Is at full capacity: ${capacityService.isAtFullCapacity(currentCapacity)}');
  
  // Example 6: Complete a booking (free up capacity)
  print('\n--- Example 6: Complete a booking (free up capacity) ---');
  final completedCapacity = capacityService.updateCapacityAfterCompletion(currentCapacity, passengerBooking);
  print('Capacity after completing passenger booking: ${completedCapacity.toString()}');
  
  // Example 7: Simulate booking validation
  print('\n--- Example 7: Simulate booking validation ---');
  final simulation = capacityService.simulateBookingValidation(completedCapacity, cargoBooking);
  print('Simulation result:');
  print('  Can accept: ${simulation['canAccept']}');
  print('  Reason: ${simulation['reason']}');
  print('  Updated capacity: ${simulation['updatedCapacity'].toString()}');
}