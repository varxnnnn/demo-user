import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is logged in on app start
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Get user data from Firestore
  Future<UserModel> getUserData(String uid) async {
    try {
      DocumentSnapshot userData = await _firestore.collection('users').doc(uid).get();
      if (userData.exists) {
        return UserModel.fromMap(userData.data() as Map<String, dynamic>);
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      if (user != null) {
        // Store login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userUid', user.uid);
        
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromMap(userData.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          phone: phone,
        );
        
        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        
        // Store login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userUid', user.uid);
        
        return newUser;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userUid');
    return await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }
}