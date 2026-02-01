import '../models/vehicle_capacity.dart';

class CapacityUtils {
  /// Format capacity for user display
  static String formatCapacityForUser(VehicleCapacity capacity) {
    String seatText = capacity.availableSeats > 0 
        ? '${capacity.availableSeats} seat${capacity.availableSeats > 1 ? 's' : ''}' 
        : 'No seats';
    
    String cargoText = capacity.availableCargoKg > 0 
        ? '${capacity.availableCargoKg}kg cargo' 
        : 'No cargo space';
    
    return '$seatText, $cargoText available';
  }

  /// Check if a specific booking fits in available capacity
  static bool doesBookingFit(VehicleCapacity capacity, BookingRequest request) {
    if (request.type == 'passenger') {
      return capacity.availableSeats >= request.passengerCount;
    } else if (request.type == 'cargo') {
      if (request.cargoWeight <= 0 || request.cargoType == 'document') {
        // Documents don't consume space
        return true;
      }
      
      if (capacity.availableCargoKg >= request.cargoWeight) {
        return true;
      }
      
      if (request.canUseSeats && capacity.availableSeats > 0) {
        // For now, assume 1 seat can hold up to 5kg of cargo
        int seatsNeeded = (request.cargoWeight / 5).ceil();
        return capacity.availableSeats >= seatsNeeded;
      }
    }
    
    return false;
  }

  /// Get user-friendly message about capacity availability
  static String getCapacityMessage(VehicleCapacity capacity, BookingRequest request) {
    if (request.type == 'passenger') {
      if (capacity.availableSeats >= request.passengerCount) {
        return 'Available - ${capacity.availableSeats} seats remain';
      } else {
        return 'Not enough seats. Only ${capacity.availableSeats} available';
      }
    } else if (request.type == 'cargo') {
      if (request.cargoWeight <= 0 || request.cargoType == 'document') {
        return 'Available - Documents accepted';
      }
      
      if (capacity.availableCargoKg >= request.cargoWeight) {
        return 'Available - ${capacity.availableCargoKg}kg space remains';
      } else if (request.canUseSeats && capacity.availableSeats > 0) {
        int seatsNeeded = (request.cargoWeight / 5).ceil();
        if (capacity.availableSeats >= seatsNeeded) {
          return 'Available - Can use ${seatsNeeded} seat${seatsNeeded > 1 ? 's' : ''}';
        } else {
          return 'Not enough capacity - Need ${seatsNeeded} seats but only ${capacity.availableSeats} available';
        }
      } else {
        return 'Not enough cargo space - Only ${capacity.availableCargoKg}kg available';
      }
    }
    
    return 'Capacity unavailable';
  }

  /// Calculate estimated capacity after booking
  static VehicleCapacity estimateCapacityAfterBooking(VehicleCapacity currentCapacity, BookingRequest request) {
    int newSeats = currentCapacity.availableSeats;
    int newCargo = currentCapacity.availableCargoKg;

    if (request.type == 'passenger') {
      newSeats -= request.passengerCount;
    } else if (request.type == 'cargo') {
      if (request.cargoWeight > 0 && request.cargoType != 'document') {
        if (currentCapacity.availableCargoKg >= request.cargoWeight) {
          newCargo -= request.cargoWeight.toInt();
        } else if (request.canUseSeats) {
          int seatsUsed = (request.cargoWeight / 5).ceil();
          newSeats -= seatsUsed;
        }
      }
    }

    // Ensure values don't go below zero
    newSeats = newSeats.clamp(0, currentCapacity.totalSeats);
    newCargo = newCargo.clamp(0, currentCapacity.totalCargoKg);

    return VehicleCapacity(
      totalSeats: currentCapacity.totalSeats,
      totalCargoKg: currentCapacity.totalCargoKg,
      availableSeats: newSeats,
      availableCargoKg: newCargo,
    );
  }
}