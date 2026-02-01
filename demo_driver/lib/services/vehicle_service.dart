import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      await _firestore.collection('vehicles').doc(vehicle.id).set(vehicle.toJson());
      print('Vehicle added successfully: \${vehicle.id}');
    } catch (e, stackTrace) {
      print('Error adding vehicle: ' + e.toString());
      print('Stack trace: ' + stackTrace.toString());
      rethrow;
    }
  }

  // Get vehicle by driver ID
  Future<Vehicle?> getVehicleByDriverId(String driverId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vehicles')
          .where('driverId', isEqualTo: driverId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return Vehicle.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Update vehicle image
  Future<void> updateVehicleImage(String vehicleId, String imageUrl) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'vehicleImageUrl': imageUrl,
    });
  }

  // Update RC book image
  Future<void> updateRcBookImage(String vehicleId, String imageUrl) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'rcBookUrl': imageUrl,
    });
  }
}