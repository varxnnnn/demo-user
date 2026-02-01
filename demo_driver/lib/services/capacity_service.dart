import '../models/vehicle_capacity.dart';

class CapacityService {
  /// Validates if a booking request can be accepted based on current capacity
  bool canAcceptBooking(VehicleCapacity currentCapacity, BookingRequest request) {
    if (request.type == 'passenger') {
      // Passenger booking
      return currentCapacity.availableSeats >= request.passengerCount;
    } else if (request.type == 'cargo') {
      // Cargo booking
      if (request.cargoWeight <= 0) {
        // Documents or paper work that doesn't consume space
        return true;
      }
      
      // Check if cargo space is available
      if (currentCapacity.availableCargoKg >= request.cargoWeight) {
        // Cargo space is available
        return true;
      }
      
      // If cargo space is full but can use seats and seats are available
      if (request.canUseSeats && currentCapacity.availableSeats > 0) {
        // For now, we'll allow it if seats are available
        // You can add more complex logic here based on cargo dimensions
        return true;
      }
      
      return false; // Neither cargo space nor seats available
    }
    
    return false; // Unknown booking type
  }

  /// Updates capacity after accepting a booking
  VehicleCapacity updateCapacityAfterBooking(VehicleCapacity currentCapacity, BookingRequest request) {
    int newAvailableSeats = currentCapacity.availableSeats;
    int newAvailableCargoKg = currentCapacity.availableCargoKg;

    if (request.type == 'passenger') {
      newAvailableSeats -= request.passengerCount;
    } else if (request.type == 'cargo') {
      // Check if it's a document (no space consumption)
      if (request.cargoWeight <= 0 || request.cargoType == 'document') {
        // Documents don't consume space
      } else if (currentCapacity.availableCargoKg >= request.cargoWeight) {
        // Use cargo space
        newAvailableCargoKg -= request.cargoWeight.toInt();
      } else if (request.canUseSeats) {
        // Use seats for cargo (convert cargo weight to seat equivalent if needed)
        // For now, let's assume 1 seat can hold up to 5kg of cargo
        int seatsNeeded = (request.cargoWeight / 5).ceil();
        newAvailableSeats -= seatsNeeded;
      }
    }

    // Ensure values don't go below zero
    newAvailableSeats = newAvailableSeats.clamp(0, currentCapacity.totalSeats);
    newAvailableCargoKg = newAvailableCargoKg.clamp(0, currentCapacity.totalCargoKg);

    return VehicleCapacity(
      totalSeats: currentCapacity.totalSeats,
      totalCargoKg: currentCapacity.totalCargoKg,
      availableSeats: newAvailableSeats,
      availableCargoKg: newAvailableCargoKg,
    );
  }

  /// Updates capacity after completing a booking (freeing up capacity)
  VehicleCapacity updateCapacityAfterCompletion(VehicleCapacity currentCapacity, BookingRequest request) {
    int newAvailableSeats = currentCapacity.availableSeats;
    int newAvailableCargoKg = currentCapacity.availableCargoKg;

    if (request.type == 'passenger') {
      newAvailableSeats += request.passengerCount;
    } else if (request.type == 'cargo') {
      // Check if it was using cargo space or seats
      if (request.cargoWeight > 0 && request.cargoType != 'document') {
        // If it was using cargo space
        if (currentCapacity.totalCargoKg - currentCapacity.availableCargoKg >= request.cargoWeight) {
          newAvailableCargoKg += request.cargoWeight.toInt();
        } else if (request.canUseSeats) {
          // If it was using seats for cargo
          int seatsUsed = (request.cargoWeight / 5).ceil();
          newAvailableSeats += seatsUsed;
        }
      }
    }

    // Ensure values don't exceed total capacity
    newAvailableSeats = newAvailableSeats.clamp(0, currentCapacity.totalSeats);
    newAvailableCargoKg = newAvailableCargoKg.clamp(0, currentCapacity.totalCargoKg);

    return VehicleCapacity(
      totalSeats: currentCapacity.totalSeats,
      totalCargoKg: currentCapacity.totalCargoKg,
      availableSeats: newAvailableSeats,
      availableCargoKg: newAvailableCargoKg,
    );
  }

  /// Gets the remaining capacity string for UI display
  String getRemainingCapacityString(VehicleCapacity capacity) {
    return "${capacity.availableSeats} seats, ${capacity.availableCargoKg} kg cargo";
  }

  /// Checks if the vehicle is at full capacity
  bool isAtFullCapacity(VehicleCapacity capacity) {
    return capacity.availableSeats <= 0 && capacity.availableCargoKg <= 0;
  }

  /// Checks if the vehicle has any available capacity
  bool hasAnyCapacity(VehicleCapacity capacity) {
    return capacity.availableSeats > 0 || capacity.availableCargoKg > 0;
  }

  /// Gets capacity status for UI display
  String getCapacityStatus(VehicleCapacity capacity) {
    if (!hasAnyCapacity(capacity)) {
      return "FULL - No capacity available";
    } else if (capacity.availableSeats <= 0 && capacity.availableCargoKg > 0) {
      return "Seats full, ${capacity.availableCargoKg}kg cargo space available";
    } else if (capacity.availableSeats > 0 && capacity.availableCargoKg <= 0) {
      return "${capacity.availableSeats} seats available, cargo space full";
    } else {
      return "${capacity.availableSeats} seats, ${capacity.availableCargoKg}kg cargo space available";
    }
  }

  /// Simulates a booking validation scenario
  Map<String, dynamic> simulateBookingValidation(VehicleCapacity currentCapacity, BookingRequest request) {
    bool canAccept = canAcceptBooking(currentCapacity, request);
    String reason = '';

    if (request.type == 'passenger') {
      if (currentCapacity.availableSeats < request.passengerCount) {
        reason = "Not enough seats. Required: ${request.passengerCount}, Available: ${currentCapacity.availableSeats}";
      }
    } else if (request.type == 'cargo') {
      if (request.cargoWeight <= 0 || request.cargoType == 'document') {
        reason = "Document/certificate booking - no space required";
      } else if (currentCapacity.availableCargoKg < request.cargoWeight) {
        if (request.canUseSeats && currentCapacity.availableSeats > 0) {
          reason = "Cargo space full but seats available (${currentCapacity.availableSeats}) for cargo if allowed";
        } else {
          reason = "Not enough cargo space. Required: ${request.cargoWeight}kg, Available: ${currentCapacity.availableCargoKg}kg";
        }
      }
    }

    return {
      'canAccept': canAccept,
      'reason': reason,
      'updatedCapacity': canAccept ? updateCapacityAfterBooking(currentCapacity, request) : currentCapacity,
    };
  }
}