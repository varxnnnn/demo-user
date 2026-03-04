import 'package:flutter/material.dart';
import '../../models/ride_completion.dart';
import '../../services/ride_completion_service.dart';
import '../../services/payment_service.dart';
import 'ride_rating_screen.dart';

class RideCompletionScreen extends StatefulWidget {
  final String tripId;
  final String driverId;
  final String userId;
  final String userName;
  final String pickupLocation;
  final String dropoffLocation;
  final double baseFare;
  final DateTime startTime;

  const RideCompletionScreen({
    Key? key,
    required this.tripId,
    required this.driverId,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.baseFare,
    required this.startTime,
  }) : super(key: key);

  @override
  State<RideCompletionScreen> createState() => _RideCompletionScreenState();
}

class _RideCompletionScreenState extends State<RideCompletionScreen> {
  late RideCompletionService _completionService;
  late PaymentService _paymentService;

  final TextEditingController _additionalChargesController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'cash'; // 'cash', 'card', 'wallet', 'upi'
  bool _isProcessing = false;
  double _baseFare = 0;

  @override
  void initState() {
    super.initState();
    _completionService = RideCompletionService();
    _paymentService = PaymentService();
    _baseFare = widget.baseFare;
  }

  @override
  void dispose() {
    _additionalChargesController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _additionalCharges {
    return double.tryParse(_additionalChargesController.text) ?? 0;
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0;
  }

  double get _totalFare {
    return (_baseFare + _additionalCharges - _discount).clamp(0, double.infinity);
  }

  Future<void> _completeAndProceedToRating() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Create completion details
      final completionDetails = RideCompletionDetails(
        tripId: widget.tripId,
        driverId: widget.driverId,
        userId: widget.userId,
        baseFare: _baseFare,
        additionalCharges: _additionalCharges,
        discount: _discount,
        totalFare: _totalFare,
        paymentMethod: _selectedPaymentMethod,
        paymentReceived: false, // Will be set after payment
        completedAt: DateTime.now(),
        completionNotes: _notesController.text,
      );

      // Process payment
      bool paymentSuccess = false;
      if (_selectedPaymentMethod == 'cash') {
        // For cash, just mark as pending confirmation
        paymentSuccess = true;
      } else {
        paymentSuccess = await _paymentService.processPayment(
          tripId: widget.tripId,
          userId: widget.userId,
          amount: _totalFare,
          paymentMethod: _selectedPaymentMethod,
        );
      }

      if (!paymentSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Complete the ride
      await _completionService.completeRide(
        tripId: widget.tripId,
        completionDetails: completionDetails,
      );

      if (mounted) {
        // Navigate to rating screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RideRatingScreen(
              tripId: widget.tripId,
              driverId: widget.driverId,
              userId: widget.userId,
              userName: widget.userName,
              totalFare: _totalFare,
              pickupLocation: widget.pickupLocation,
              dropoffLocation: widget.dropoffLocation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Summary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Details Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trip Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passenger',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.pickupLocation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_pin, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.dropoffLocation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _getDuration(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Fare Breakdown
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fare Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFareRowWithInput(
                        label: 'Base Fare',
                        amount: '₹${_baseFare.toStringAsFixed(2)}',
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _buildFareRowWithInput(
                        label: 'Additional Charges',
                        controller: _additionalChargesController,
                        hint: 'Damage, tolls, etc.',
                      ),
                      const SizedBox(height: 12),
                      _buildFareRowWithInput(
                        label: 'Discount',
                        controller: _discountController,
                        hint: 'Promo, adjustment',
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Fare',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_totalFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentOption('Cash', 'cash'),
                      _buildPaymentOption('Card', 'card'),
                      _buildPaymentOption('UPI', 'upi'),
                      _buildPaymentOption('Wallet', 'wallet'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any issues or comments...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Complete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _completeAndProceedToRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Ride & Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareRowWithInput({
    required String label,
    String? amount,
    TextEditingController? controller,
    String? hint,
    bool readOnly = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          flex: 1,
          child: controller != null
              ? TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    prefix: const Text('₹'),
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : Text(
                  amount ?? '₹0.00',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedPaymentMethod,
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selectedPaymentMethod = newValue);
            }
          },
        ),
        Text(label),
      ],
    );
  }

  String _getDuration() {
    final now = DateTime.now();
    final duration = now.difference(widget.startTime);
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours h $remainingMinutes m';
    } else {
      return '$remainingMinutes m';
    }
  }
}
