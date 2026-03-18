class VehicleCapacity {
  int totalSeats;
  int totalCargoKg;
  int availableSeats;
  int availableCargoKg;

  VehicleCapacity({
    required this.totalSeats,
    required this.totalCargoKg,
    required this.availableSeats,
    required this.availableCargoKg,
  });

  factory VehicleCapacity.initial(int totalSeats, int totalCargoKg) {
    return VehicleCapacity(
      totalSeats: totalSeats,
      totalCargoKg: totalCargoKg,
      availableSeats: totalSeats,
      availableCargoKg: totalCargoKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSeats': totalSeats,
      'totalCargoKg': totalCargoKg,
      'availableSeats': availableSeats,
      'availableCargoKg': availableCargoKg,
    };
  }

  factory VehicleCapacity.fromJson(Map<String, dynamic> json) {
    return VehicleCapacity(
      totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 0,
      totalCargoKg: (json['totalCargoKg'] as num?)?.toInt() ?? 0,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      availableCargoKg: (json['availableCargoKg'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'VehicleCapacity(totalSeats: $totalSeats, totalCargoKg: $totalCargoKg, availableSeats: $availableSeats, availableCargoKg: $availableCargoKg)';
  }
}

class BookingRequest {
  String id;
  String type; // 'passenger' or 'cargo'
  int passengerCount; // for passenger bookings
  double cargoWeight; // for cargo bookings in kg
  bool canUseSeats; // if cargo can use seats when cargo space is full
  String cargoType; // 'document', 'parcel', 'luggage', etc.
  String pickupLocation;
  String destination;
  DateTime timestamp;

  BookingRequest({
    required this.id,
    required this.type,
    this.passengerCount = 0,
    this.cargoWeight = 0.0,
    this.canUseSeats = false,
    this.cargoType = 'parcel',
    required this.pickupLocation,
    required this.destination,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'passengerCount': passengerCount,
      'cargoWeight': cargoWeight,
      'canUseSeats': canUseSeats,
      'cargoType': cargoType,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'] ?? '',
      type: json['type'] ?? 'passenger',
      passengerCount: json['passengerCount'] ?? 0,
      cargoWeight: (json['cargoWeight'] ?? 0.0).toDouble(),
      canUseSeats: json['canUseSeats'] ?? false,
      cargoType: json['cargoType'] ?? 'parcel',
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ActiveTrip {
  String id;
  List<BookingRequest> bookings;
  VehicleCapacity currentCapacity;
  DateTime startTime;
  String status; // 'active', 'completed', 'cancelled'

  ActiveTrip({
    required this.id,
    required this.bookings,
    required this.currentCapacity,
    required this.startTime,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookings': bookings.map((e) => e.toJson()).toList(),
      'currentCapacity': currentCapacity.toJson(),
      'startTime': startTime.toIso8601String(),
      'status': status,
    };
  }

  factory ActiveTrip.fromJson(Map<String, dynamic> json) {
    return ActiveTrip(
      id: json['id'] ?? '',
      bookings: (json['bookings'] as List<dynamic>?)
              ?.map((e) => BookingRequest.fromJson(e))
              .toList() ??
          [],
      currentCapacity: VehicleCapacity.fromJson(json['currentCapacity']),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'active',
    );
  }
}