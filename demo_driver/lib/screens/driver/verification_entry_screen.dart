import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class VerificationEntryScreen extends StatefulWidget {
  final String tripId;
  final String userName;
  final String pickupLocation;
  
  const VerificationEntryScreen({
    Key? key,
    required this.tripId,
    required this.userName,
    required this.pickupLocation,
  }) : super(key: key);

  @override
  State<VerificationEntryScreen> createState() => _VerificationEntryScreenState();
}

class _VerificationEntryScreenState extends State<VerificationEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;
  bool _codeVerified = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final enteredCode = _codeController.text.trim();

      if (enteredCode.length != 6) {
        setState(() {
          _error = 'Code must be 6 digits';
          _isVerifying = false;
        });
        return;
      }

      // Get the trip document to check the verification code
      final tripDoc =
          await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();

      if (!tripDoc.exists) {
        setState(() {
          _error = 'Trip not found';
          _isVerifying = false;
        });
        return;
      }

      final tripData = tripDoc.data() as Map<String, dynamic>;
      final verificationData =
          tripData['verification'] as Map<String, dynamic>?;

      if (verificationData == null) {
        setState(() {
          _error = 'Verification code not generated yet';
          _isVerifying = false;
        });
        return;
      }

      final correctCode = verificationData['code'] as String?;

      if (correctCode == null) {
        setState(() {
          _error = 'Verification code not found';
          _isVerifying = false;
        });
        return;
      }

      if (enteredCode == correctCode) {
        // Code is correct! Update trip status
        final authService =
            Provider.of<AuthService>(context, listen: false);
        final driverId = authService.currentUser?.uid;

        if (driverId != null) {
          // Update trip status to in_progress
          await FirebaseFirestore.instance
              .collection('trips')
              .doc(widget.tripId)
              .update({
            'status': 'in_progress', // Ride started
            'verifiedAt': FieldValue.serverTimestamp(),
            'verification.status': 'verified',
          });

          // Update active trip status
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverId)
              .collection('activeTrips')
              .doc(widget.tripId)
              .update({
            'status': 'arrived_at_pickup', // Driver has arrived
            'verifiedAt': FieldValue.serverTimestamp(),
          });

          // Get driver's current vehicle capacity
          final driverDoc =
              await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
          
          if (driverDoc.exists) {
            final driverData = driverDoc.data() as Map<String, dynamic>;
            int currentCapacity = (driverData['vehicleCapacity'] ?? 4) as int;
            
            // Reduce capacity by 1 (one passenger picked up)
            int updatedCapacity = currentCapacity - 1;
            
            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .update({
              'vehicleCapacity': updatedCapacity,
              'lastCapacityUpdate': FieldValue.serverTimestamp(),
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code verified! Ride in progress'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            setState(() {
              _codeVerified = true;
              _isVerifying = false;
            });

            // Return to previous screen after a short delay
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        }
      } else {
        setState(() {
          _error = 'Invalid code. Please try again';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error verifying code: $e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Pickup'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passenger Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pickupLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Passenger',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Instructions
            const Text(
              'Ask the passenger for the 6-digit verification code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The code was generated when you arrived at the pickup location',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Code Input Field
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              enabled: !_codeVerified && !_isVerifying,
              decoration: InputDecoration(
                labelText: '6-Digit Code',
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isVerifying || _codeVerified) ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _codeVerified
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 8),
                              Text('Code Verified!'),
                            ],
                          )
                        : const Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Driver capacity will be updated once code is verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:provider/provider.dart';
