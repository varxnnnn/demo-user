import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  /// Monitor a trip document and generate a 4-digit code when driver is within [radiusMeters] of user.
  void monitorTrip(String tripId, {double radiusMeters = 500}) {
    _tripSubscription = _firestore.collection('trips').doc(tripId).snapshots().listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final driverLoc = data['driverLocation'];
      final userLoc = data['from']; // expecting {latitude, longitude}

      if (driverLoc == null || userLoc == null) return;

      final double dLat = (driverLoc['latitude'] as num).toDouble();
      final double dLng = (driverLoc['longitude'] as num).toDouble();
      final double uLat = (userLoc['latitude'] as num).toDouble();
      final double uLng = (userLoc['longitude'] as num).toDouble();

      final distanceMeters = Geolocator.distanceBetween(dLat, dLng, uLat, uLng);

      // If within radius and no active verification code, generate one
      final verification = data['verification'];
      final now = DateTime.now();
      final bool hasActiveCode = verification != null && verification['expiresAt'] != null
          && (verification['verified'] == null || verification['verified'] == false)
          && (verification['expiresAt'] is Timestamp ?
              (verification['expiresAt'] as Timestamp).toDate().isAfter(now) : true);

      if (distanceMeters <= radiusMeters && !hasActiveCode) {
        await _generateAndStoreCode(tripId);
      }
    });
  }

  Future<void> _generateAndStoreCode(String tripId, {int ttlSeconds = 120}) async {
    final rnd = Random();
    final code = (rnd.nextInt(9000) + 1000).toString(); // 4-digit
    final expiresAt = Timestamp.fromDate(DateTime.now().add(Duration(seconds: ttlSeconds)));

    await _firestore.collection('trips').doc(tripId).update({
      'verification': {
        'code': code,
        'generatedAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'verified': false,
      },
      'lastVerificationGeneratedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verify code entered by driver (returns true if matched and not expired)
  Future<bool> verifyCode(String tripId, String code) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    final verification = data['verification'];
    if (verification == null) return false;

    final storedCode = verification['code']?.toString();
    final expiresAt = verification['expiresAt'] as Timestamp?;
    final now = DateTime.now();

    if (storedCode == code && expiresAt != null && expiresAt.toDate().isAfter(now)) {
      // Mark verified and update trip status to in_progress
      await _firestore.collection('trips').doc(tripId).update({
        'verification.verified': true,
        'status': 'in_progress',
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    }

    return false;
  }

  void dispose() {
    _tripSubscription?.cancel();
    _tripSubscription = null;
  }
}
