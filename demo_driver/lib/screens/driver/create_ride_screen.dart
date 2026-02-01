import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _priceController = TextEditingController(text: '100');
  String _urgency = 'medium';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ride'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Ride Details'),
                const SizedBox(height: 16),
                _buildInputField(
                  'Pickup Location',
                  Icons.location_on,
                  _pickupController,
                  'Enter pickup address',
                  TextInputType.streetAddress,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'Dropoff Location', 
                  Icons.location_on,
                  _dropoffController,
                  'Enter dropoff address',
                  TextInputType.streetAddress,
                ),
                const SizedBox(height: 16),
                _buildPriceSection(),
                const SizedBox(height: 16),
                _buildUrgencySection(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitRideRequest,
                    icon: const Icon(Icons.send),
                    label: const Text('Request Ride'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A1B9A),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A1B9A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInputField(
              'Offered Price (₹)',
              Icons.currency_rupee,
              _priceController,
              'Enter amount',
              TextInputType.number,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickPrice(50),
                _buildQuickPrice(100),
                _buildQuickPrice(200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrice(int amount) {
    return GestureDetector(
      onTap: () => _priceController.text = amount.toString(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _priceController.text == amount.toString() 
              ? const Color(0xFF6A1B9A) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _priceController.text == amount.toString() 
                ? const Color(0xFF6A1B9A) 
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          '₹$amount',
          style: TextStyle(
            color: _priceController.text == amount.toString() 
                ? Colors.white 
                : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Urgency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUrgencyOption('Low', 'low', Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUrgencyOption('Medium', 'medium', Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUrgencyOption('High', 'high', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyOption(String label, String value, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _urgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _urgency == value ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _urgency == value ? color : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _urgency == value ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _submitRideRequest() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create ride request (in real app, this would save to Firestore)
    final rideRequest = {
      'id': const Uuid().v4(),
      'userId': 'user_123', // Would get from auth
      'userName': 'Test User',
      'userRating': 4.5,
      'pickupLocation': _pickupController.text.trim(),
      'dropoffLocation': _dropoffController.text.trim(),
      'offeredPrice': double.tryParse(_priceController.text) ?? 100.0,
      'urgency': _urgency,
      'requestedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    };

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back
    Navigator.pop(context);
  }
}