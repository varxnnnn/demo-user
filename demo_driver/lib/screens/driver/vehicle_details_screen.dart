import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import 'vehicle_capacity_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  Driver? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final driverData = await authService.getDriverData(currentUser.uid);
        
        // If driver doesn't have vehicle data but has capacity, create vehicle data
        if (driverData != null && 
            driverData.vehicle == null && 
            driverData.vehicleCapacity != null) {
          await _createVehicleForDriver(currentUser.uid, driverData);
          // Reload data after creating vehicle
          final updatedDriverData = await authService.getDriverData(currentUser.uid);
          if (mounted) {
            setState(() {
              _driver = updatedDriverData;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _driver = driverData;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicle data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createVehicleForDriver(String driverId, Driver driverData) async {
    try {
      final vehicleService = Provider.of<VehicleService>(context, listen: false);
      
      // Create vehicle data from driver info
      final vehicle = Vehicle(
        id: '${driverId}_${DateTime.now().millisecondsSinceEpoch}',
        driverId: driverId,
        vehicleType: 'Car',
        brand: 'Unknown',
        model: 'Unknown',
        registrationNumber: 'Unknown',
        rcBookUrl: '',
        vehicleImageUrl: '',
        isVerified: false,
        createdAt: DateTime.now(),
      );
      
      await vehicleService.addVehicle(vehicle);
      print('Created default vehicle data for driver: $driverId');
    } catch (e) {
      print('Error creating vehicle data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
              ),
            )
          : _driver?.vehicleCapacity == null
              ? _buildNoVehicleData()
              : _buildVehicleDetails(),
    );
  }

  Widget _buildNoVehicleData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Vehicle Data Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please set up your vehicle capacity first',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleCapacityScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Setup Vehicle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails() {
    final vehicleCapacity = _driver!.vehicleCapacity!;
    final totalSeats = vehicleCapacity.totalSeats;
    final availableSeats = vehicleCapacity.availableSeats;
    final filledSeats = totalSeats - availableSeats;
    
    final totalCargo = vehicleCapacity.totalCargoKg;
    final availableCargo = vehicleCapacity.availableCargoKg;
    final filledCargo = totalCargo - availableCargo;
    
    final vehicle = _driver!.vehicle;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Vehicle Image
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Vehicle Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildVehicleImage(vehicle),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Vehicle Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Vehicle',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vehicle != null ? '${vehicle.brand.toUpperCase()} ${vehicle.model.toUpperCase()}' : 'Vehicle Info',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg: ${vehicle?.registrationNumber ?? 'Not Set'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Driver: ${_driver?.name ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verification Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle?.isVerified == true ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            vehicle?.isVerified == true ? Icons.verified : Icons.pending,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle?.isVerified == true ? 'Verified' : 'Pending',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

          const SizedBox(height: 24),

          // Vehicle Information Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(height: 15),
                _buildInfoRow('Brand', vehicle?.brand ?? 'N/A'),
                _buildInfoRow('Model', vehicle?.model ?? 'N/A'),
                _buildInfoRow('Registration', vehicle?.registrationNumber ?? 'N/A'),
                _buildInfoRow('Vehicle Type', vehicle?.vehicleType ?? 'N/A'),
                _buildInfoRow('RC Book', vehicle?.rcBookUrl.isNotEmpty == true ? 'Uploaded' : 'Not Uploaded'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seats Capacity Section
          _buildCapacitySection(
            title: 'Seating Capacity',
            icon: Icons.event_seat,
            total: totalSeats,
            available: availableSeats,
            filled: filledSeats,
            unit: 'seats',
            color: Colors.blue,
          ),

          const SizedBox(height: 24),

          // Cargo Capacity Section
          _buildCapacitySection(
            title: 'Cargo Capacity',
            icon: Icons.local_shipping,
            total: totalCargo,
            available: availableCargo,
            filled: filledCargo,
            unit: 'kg',
            color: Colors.orange,
          ),

          const SizedBox(height: 24),

          // Vehicle Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _driver?.isVerified == true ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _driver?.isVerified == true ? Icons.verified : Icons.pending,
                            size: 16,
                            color: _driver?.isVerified == true ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _driver?.isVerified == true ? 'Verified' : 'Pending Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _driver?.isVerified == true ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _driver?.onlineStatus == 'online' ? Colors.green[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _driver?.onlineStatus == 'online' ? Icons.circle : Icons.circle_outlined,
                            size: 16,
                            color: _driver?.onlineStatus == 'online' ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _driver?.onlineStatus == 'online' ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _driver?.onlineStatus == 'online' ? Colors.green : Colors.grey,
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

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleCapacityScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Capacity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showVehicleInfo();
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('RC Book'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6A1B9A)),
                    foregroundColor: const Color(0xFF6A1B9A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImage(Vehicle? vehicle) {
    if (vehicle?.vehicleImageUrl != null && vehicle!.vehicleImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: vehicle.vehicleImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.white,
          child: Icon(
            Icons.directions_car,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.white,
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      );
    }
    
    return Icon(
      Icons.directions_car,
      color: Colors.white,
      size: 40,
    );
  }

  Widget _buildCapacitySection({
    required String title,
    required IconData icon,
    required int total,
    required int available,
    required int filled,
    required String unit,
    required Color color,
  }) {
    final fillPercentage = total > 0 ? (filled / total).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Visual Representation
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Background (Total Capacity)
                Positioned.fill(
                  child: Row(
                    children: List.generate(
                      total > 8 ? 8 : total,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: unit == 'seats'
                              ? const Center(
                                  child: Icon(
                                    Icons.event_seat,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.inventory_2,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Filled Seats/Cargo
                if (filled > 0)
                  Positioned.fill(
                    child: Row(
                      children: List.generate(
                        filled > 8 ? 8 : filled,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withOpacity(0.8)),
                            ),
                            child: unit == 'seats'
                                ? const Center(
                                    child: Icon(
                                      Icons.event_seat,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Available indicator
                if (available > 0)
                  Positioned.fill(
                    child: Row(
                      children: List.generate(
                        available > 8 ? 8 : available,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: unit == 'seats'
                                ? const Center(
                                    child: Icon(
                                      Icons.event_seat,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '$total $unit', color),
              _buildStatItem('Available', '$available $unit', Colors.green),
              _buildStatItem('Filled', '$filled $unit', color.withOpacity(0.8)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillPercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: fillPercentage >= 0.8 
                      ? Colors.red 
                      : fillPercentage >= 0.6 
                          ? Colors.orange 
                          : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(fillPercentage * 100).toInt()}% Filled',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fillPercentage >= 0.8 
                  ? Colors.red 
                  : fillPercentage >= 0.6 
                      ? Colors.orange 
                      : color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showVehicleInfo() {
    final vehicle = _driver?.vehicle;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Vehicle Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicle?.vehicleImageUrl != null && vehicle!.vehicleImageUrl.isNotEmpty) ...[
                  const Text('Vehicle Image:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: vehicle.vehicleImageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildInfoRow('Driver Name', _driver?.name ?? 'N/A'),
                _buildInfoRow('Email', _driver?.email ?? 'N/A'),
                _buildInfoRow('Phone', _driver?.phone ?? 'N/A'),
                _buildInfoRow('License Number', _driver?.licenseNumber ?? 'N/A'),
                _buildInfoRow('Aadhar Number', _driver?.aadharNumber ?? 'N/A'),
                _buildInfoRow('PAN Number', _driver?.panNumber ?? 'N/A'),
                _buildInfoRow('Brand', vehicle?.brand ?? 'N/A'),
                _buildInfoRow('Model', vehicle?.model ?? 'N/A'),
                _buildInfoRow('Registration Number', vehicle?.registrationNumber ?? 'N/A'),
                _buildInfoRow('Vehicle Type', vehicle?.vehicleType ?? 'N/A'),
                _buildInfoRow('Driver Verification Status', 
                    _driver?.isVerified == true ? 'Verified' : 'Pending'),
                _buildInfoRow('Vehicle Verification Status', 
                    vehicle?.isVerified == true ? 'Verified' : 'Pending'),
                if (vehicle?.rcBookUrl != null && vehicle!.rcBookUrl.isNotEmpty)
                  _buildInfoRow('RC Book', 'Uploaded (Tap to view)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            if (vehicle?.rcBookUrl != null && vehicle!.rcBookUrl.isNotEmpty)
              TextButton(
                onPressed: () {
                  _showRcBook(vehicle.rcBookUrl);
                },
                child: const Text('View RC Book'),
              ),
          ],
        );
      },
    );
  }

  void _showRcBook(String rcBookUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                AppBar(
                  title: const Text('RC Book'),
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: rcBookUrl,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            SizedBox(height: 10),
                            Text('Unable to load RC Book'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}