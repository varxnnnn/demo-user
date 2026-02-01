import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;

  // Initialize user
  Future<void> initializeUser() async {
    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser != null) {
      // User is logged in via Firebase
      await _loadUserData(firebaseUser.uid);
    } else {
      // Check if user was previously logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userUid = prefs.getString('userUid');

      if (isLoggedIn && userUid != null) {
        // User was previously logged in, try to load their data
        await _loadUserData(userUid);
      } else {
        notifyListeners();
      }
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final user = await _authService.getUserData(uid);
      _user = user;
    } catch (e) {
      print('Error loading user data: $e');
      // Clear user data and redirect to login
      _user = null;
      // The splash screen will handle navigation to login
    }
    notifyListeners();
  }

  // Register user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final newUser = await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
        phone,
      );
      if (newUser != null) {
        _user = newUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Login user
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // Check if user is logged in
  bool get isLoggedIn {
    return _user != null;
  }
}