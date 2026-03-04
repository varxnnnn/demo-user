import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_capacity.dart';
import 'vehicle.dart';

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String aadharNumber;
  final String panNumber;
  final String profileImageUrl;
  final bool isVerified;
  final DateTime createdAt;
  final String? onlineStatus;
  final VehicleCapacity? vehicleCapacity;
  final Vehicle? vehicle;
  final double? locationLatitude;
  final double? locationLongitude;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.aadharNumber,
    required this.panNumber,
    required this.profileImageUrl,
    required this.isVerified,
    required this.createdAt,
    this.onlineStatus,
    this.vehicleCapacity,
    this.vehicle,
    this.locationLatitude,
    this.locationLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'onlineStatus': onlineStatus,
      if (vehicleCapacity != null) 'vehicleCapacity': vehicleCapacity!.toJson(),
      if (vehicle != null) 'vehicle': vehicle!.toJson(),
      'location': {
        'latitude': locationLatitude,
        'longitude': locationLongitude,
      },
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      licenseNumber: json['licenseNumber'],
      aadharNumber: json['aadharNumber'],
      panNumber: json['panNumber'],
      profileImageUrl: json['profileImageUrl'] ?? '',
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      onlineStatus: json['onlineStatus'] ?? 'offline',
      vehicleCapacity: json['vehicleCapacity'] != null 
          ? VehicleCapacity.fromJson(json['vehicleCapacity']) 
          : null,
      vehicle: json['vehicle'] != null 
          ? Vehicle.fromJson(json['vehicle']) 
          : null,
      locationLatitude: json['location'] != null 
          ? (json['location']['latitude'] as num?)?.toDouble() 
          : null,
      locationLongitude: json['location'] != null 
          ? (json['location']['longitude'] as num?)?.toDouble() 
          : null,
    );
  }

  // Static method to create Driver with vehicle data
  static Future<Driver> fromIdWithVehicle(String driverId, FirebaseFirestore firestore) async {
    try {
      // Get driver data
      DocumentSnapshot driverSnapshot = await firestore.collection('drivers').doc(driverId).get();
      if (!driverSnapshot.exists) throw Exception('Driver not found');
      
      Map<String, dynamic> driverData = driverSnapshot.data() as Map<String, dynamic>;
      
      // Get vehicle data
      QuerySnapshot vehicleSnapshot = await firestore
          .collection('vehicles')
          .where('driverId', isEqualTo: driverId)
          .limit(1)
          .get();
      
      if (vehicleSnapshot.docs.isNotEmpty) {
        driverData['vehicle'] = vehicleSnapshot.docs.first.data();
      }
      
      // Ensure location data is available
      if (driverData['location'] != null) {
        driverData['locationLatitude'] = (driverData['location']['latitude'] as num?)?.toDouble();
        driverData['locationLongitude'] = (driverData['location']['longitude'] as num?)?.toDouble();
      }
      
      return Driver.fromJson(driverData);
    } catch (e) {
      throw Exception('Error loading driver with vehicle: $e');
    }
  }
}