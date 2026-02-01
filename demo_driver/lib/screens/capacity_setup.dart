import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/capacity_provider.dart';
import '../screens/driver/dashboard.dart';

class CapacitySetupScreen extends StatefulWidget {
  const CapacitySetupScreen({Key? key}) : super(key: key);

  @override
  State<CapacitySetupScreen> createState() => _CapacitySetupScreenState();
}

class _CapacitySetupScreenState extends State<CapacitySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seatsController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _driverId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCapacitySetup();
  }

  Future<void> _checkCapacitySetup() async {
    // Check if capacity is already set up
    final capacityProvider = Provider.of<CapacityProvider>(context, listen: false);
    
    // In a real app, you would get the driver ID from auth provider
    // For now, we'll use a placeholder
    String driverId = 'driver_123'; // This would come from auth provider
    
    // Check if capacity is already set up
    final existingCapacity = await capacityProvider.getDriverCapacity(driverId);
    if (existingCapacity != null && 
        existingCapacity.totalSeats > 0 && 
        existingCapacity.totalCargoKg > 0) {
      // If capacity is already set up, redirect to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverDashboard()),
        );
      }
      return;
    }
    
    setState(() {
      _driverId = driverId;
    });
  }

  Future<void> _submitCapacity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Driver ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final capacityProvider = Provider.of<CapacityProvider>(context, listen: false);
      
      await capacityProvider.initializeDriverCapacity(
        _driverId!,
        int.parse(_seatsController.text),
        int.parse(_cargoController.text),
      );

      // Navigate to dashboard after successful setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up capacity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Vehicle Capacity'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle Capacity Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your vehicle\'s capacity details',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Seats Input
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of seats';
                  }
                  final seats = int.tryParse(value);
                  if (seats == null || seats <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  if (seats > 20) {
                    return 'Seats should be 20 or less';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Total Seats',
                  hintText: 'e.g., 4',
                  prefixIcon: Icon(Icons.event_seat),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Cargo Capacity Input
              TextFormField(
                controller: _cargoController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cargo capacity';
                  }
                  final cargo = double.tryParse(value);
                  if (cargo == null || cargo <= 0) {
                    return 'Please enter a valid cargo capacity';
                  }
                  if (cargo > 1000) {
                    return 'Cargo capacity should be 1000 kg or less';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Cargo Capacity (kg)',
                  hintText: 'e.g., 10',
                  prefixIcon: Icon(Icons.local_shipping),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              
              // Info Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Capacity Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(text: '• Seats: '),
                          TextSpan(text: 'Number of passengers your vehicle can accommodate\n\n'),
                          TextSpan(text: '• Cargo: '),
                          TextSpan(text: 'Maximum weight (in kg) your vehicle can carry\n\n'),
                          TextSpan(text: '• Documents: '),
                          TextSpan(text: 'Certificates/papers don\'t consume space'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCapacity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Set Capacity & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _cargoController.dispose();
    super.dispose();
  }
}