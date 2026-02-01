import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String licenseNumber,
    required String aadharNumber,
    required String panNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        print('User created successfully: \${result.user!.uid}');
        // Save driver data to Firestore
        await _firestore.collection('drivers').doc(result.user!.uid).set({
          'id': result.user!.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'licenseNumber': licenseNumber,
          'aadharNumber': aadharNumber,
          'panNumber': panNumber,
          'profileImageUrl': '',
          'isVerified': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('Driver data saved to Firestore for user: \${result.user!.uid}');
      }

      return result;
    } catch (e, stackTrace) {
      print('Error registering user: ' + e.toString());
      print('Stack trace: ' + stackTrace.toString());
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get driver data
  Future<Driver?> getDriverData(String driverId) async {
    try {
      // Get driver data with vehicle information
      final driverWithVehicle = await Driver.fromIdWithVehicle(driverId, _firestore);
      return driverWithVehicle;
    } catch (e) {
      return null;
    }
  }

  // Save driver data
  Future<void> saveDriverData(String driverId, Map<String, dynamic> driverData) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update(driverData);
      print('Driver data updated successfully: $driverId');
    } catch (e) {
      print('Error updating driver data: $e');
      rethrow;
    }
  }

  // Update driver profile image
  Future<void> updateProfileImage(String driverId, String imageUrl) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'profileImageUrl': imageUrl,
    });
  }
}