import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/capacity_provider.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';

class VehicleCapacityScreen extends StatefulWidget {
  const VehicleCapacityScreen({Key? key}) : super(key: key);

  @override
  State<VehicleCapacityScreen> createState() => _VehicleCapacityScreenState();
}

class _VehicleCapacityScreenState extends State<VehicleCapacityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seatsController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _driverId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDriverId();
    _loadExistingData();
  }

  Future<void> _loadDriverId() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      setState(() {
        _driverId = authService.currentUser!.uid;
      });
    }
  }

  Future<void> _loadExistingData() async {
    if (_driverId == null) return;
    
    try {
      // Load existing capacity data from driver document
      final authService = Provider.of<AuthService>(context, listen: false);
      final driverData = await authService.getDriverData(_driverId!);
      
      if (driverData != null && driverData.vehicleCapacity != null) {
        setState(() {
          _seatsController.text = driverData.vehicleCapacity!.totalSeats.toString();
          _cargoController.text = driverData.vehicleCapacity!.totalCargoKg.toString();
        });
      } else {
        // Load from capacity provider as fallback
        final capacityProvider = Provider.of<CapacityProvider>(context, listen: false);
        final existingCapacity = await capacityProvider.getDriverCapacity(_driverId!);
        
        if (existingCapacity != null) {
          setState(() {
            _seatsController.text = existingCapacity.totalSeats.toString();
            _cargoController.text = existingCapacity.totalCargoKg.toString();
          });
        }
      }
      
      // Load existing vehicle data
      final vehicleService = Provider.of<VehicleService>(context, listen: false);
      final vehicle = await vehicleService.getVehicleByDriverId(_driverId!);
      
      if (vehicle != null) {
        setState(() {
          // We'll need to add controllers for vehicle data if needed
          // For now, we're just loading capacity data
        });
      }
    } catch (e) {
      // Handle error silently
      print('Error loading existing data: $e');
    }
  }

  Future<void> _saveCapacity() async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle capacity saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving capacity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetCapacity() async {
    if (_driverId == null) return;

    setState(() => _isLoading = true);

    try {
      final capacityProvider = Provider.of<CapacityProvider>(context, listen: false);
      await capacityProvider.resetCapacity(
        int.parse(_seatsController.text),
        int.parse(_cargoController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Available capacity has been reset to match total capacity.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting capacity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Capacity'),
        backgroundColor: const Color(0xFF6A1B9A),
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
                'Vehicle Capacity Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your vehicle\'s seating and cargo capacity',
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
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Capacity Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Seats: Number of passengers your vehicle can accommodate\n'
                      '• Cargo: Maximum weight (in kg) your vehicle can carry\n'
                      '• Documents: Certificates/papers don\'t consume space',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Reset Capacity Button (for debugging)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _resetCapacity,
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  label: const Text(
                    'Reset Available Capacity',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCapacity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Capacity',
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