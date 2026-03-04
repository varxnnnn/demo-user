import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process payment for a ride
  Future<bool> processPayment({
    required String tripId,
    required String userId,
    required double amount,
    required String paymentMethod, // 'cash', 'card', 'wallet', 'upi'
  }) async {
    try {
      // In a real app, you would integrate with Stripe, Razorpay, etc.
      // For now, we'll simulate payment processing
      
      final paymentId = '${tripId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Record payment in Firestore
      await _firestore.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'tripId': tripId,
        'userId': userId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'transactionId': _generateTransactionId(),
      });

      // Log payment for driver
      await _firestore.collection('trips').doc(tripId).update({
        'paymentStatus': 'completed',
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
        'paidAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  /// Generate transaction ID
  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  /// Get wallet balance (if using in-app wallet)
  Future<double> getWalletBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return (userDoc.data()?['walletBalance'] ?? 0).toDouble();
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  /// Add funds to wallet
  Future<bool> addFundsToWallet({
    required String userId,
    required double amount,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
        'lastWalletUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding funds: $e');
      return false;
    }
  }

  /// Deduct from wallet
  Future<bool> deductFromWallet({
    required String userId,
    required double amount,
  }) async {
    try {
      final balance = await getWalletBalance(userId);
      
      if (balance < amount) {
        print('Insufficient wallet balance');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
        'lastWalletUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error deducting from wallet: $e');
      return false;
    }
  }

  /// Apply coupon/promo code
  Future<double?> validateAndApplyCoupon({
    required String couponCode,
    required double totalAmount,
    required String userId,
  }) async {
    try {
      final couponDoc = await _firestore
          .collection('coupons')
          .doc(couponCode.toUpperCase())
          .get();

      if (!couponDoc.exists) {
        return null; // Invalid coupon
      }

      final data = couponDoc.data() ?? {};
      final isActive = data['isActive'] ?? false;
      final minAmount = (data['minAmount'] ?? 0).toDouble();
      final discount = (data['discount'] ?? 0).toDouble();
      final maxUses = (data['maxUses'] ?? 100).toInt();
      final currentUses = (data['currentUses'] ?? 0).toInt();

      if (!isActive || totalAmount < minAmount || currentUses >= maxUses) {
        return null;
      }

      // Update coupon usage
      await _firestore.collection('coupons').doc(couponCode.toUpperCase()).update({
        'currentUses': currentUses + 1,
        'usedBy': FieldValue.arrayUnion([userId]),
      });

      // Calculate discount amount
      return discount;
    } catch (e) {
      print('Error validating coupon: $e');
      return null;
    }
  }
}
