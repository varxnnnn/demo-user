import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/capacity_provider.dart';

class DriverDashboard extends StatefulWidget {
  static const String id = 'driver_dashboard';

  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CapacityProvider>(
        builder: (context, capacityProvider, child) {
          final capacity = capacityProvider.currentCapacity;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capacity Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Capacity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Capacity Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: capacity != null && capacityProvider.currentCapacity != null
                              ? (capacityProvider.currentCapacity!.availableSeats <= 0 && capacityProvider.currentCapacity!.availableCargoKg <= 0)
                                  ? Colors.red.shade100
                                  : (capacityProvider.currentCapacity!.availableSeats > 0 || capacityProvider.currentCapacity!.availableCargoKg > 0)
                                      ? Colors.green.shade100
                                      : Colors.grey.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: capacity != null && capacityProvider.currentCapacity != null
                                ? (capacityProvider.currentCapacity!.availableSeats <= 0 && capacityProvider.currentCapacity!.availableCargoKg <= 0)
                                    ? Colors.red
                                    : (capacityProvider.currentCapacity!.availableSeats > 0 || capacityProvider.currentCapacity!.availableCargoKg > 0)
                                        ? Colors.green
                                        : Colors.grey
                                : Colors.grey,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capacity != null
                                  ? capacityProvider.capacityStatus
                                  : 'Initializing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: capacity != null && capacityProvider.currentCapacity != null
                                    ? (capacityProvider.currentCapacity!.availableSeats <= 0 && capacityProvider.currentCapacity!.availableCargoKg <= 0)
                                        ? Colors.red
                                        : (capacityProvider.currentCapacity!.availableSeats > 0 || capacityProvider.currentCapacity!.availableCargoKg > 0)
                                            ? Colors.green
                                            : Colors.grey
                                    : Colors.grey,
                              ),
                            ),
                            if (capacity != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Seats: ${capacity.availableSeats}/${capacity.totalSeats}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Cargo: ${capacity.availableCargoKg}/${capacity.totalCargoKg} kg',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Toggle online status
                            final provider = Provider.of<CapacityProvider>(context, listen: false);
                            if (capacityProvider.isCapacityInitialized) {
                              provider.updateOnlineStatus(capacityProvider.currentCapacity!.availableSeats > 0 || capacityProvider.currentCapacity!.availableCargoKg > 0 ? 'offline' : 'online');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  capacityProvider.currentCapacity != null && 
                                      (capacityProvider.currentCapacity!.availableSeats > 0 || 
                                       capacityProvider.currentCapacity!.availableCargoKg > 0)
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: capacityProvider.currentCapacity != null && 
                                      (capacityProvider.currentCapacity!.availableSeats > 0 || 
                                       capacityProvider.currentCapacity!.availableCargoKg > 0)
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  capacityProvider.currentCapacity != null && 
                                      (capacityProvider.currentCapacity!.availableSeats > 0 || 
                                       capacityProvider.currentCapacity!.availableCargoKg > 0)
                                      ? 'Online'
                                      : 'Offline',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Reset capacity (for demo/testing purposes)
                            if (capacityProvider.isCapacityInitialized && capacity != null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Reset Capacity'),
                                  content: const Text('Are you sure you want to reset your capacity to full?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await Provider.of<CapacityProvider>(context, listen: false)
                                            .resetCapacity(capacity.totalSeats, capacity.totalCargoKg);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.refresh,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Reset',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent Bookings Section
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: 3, // Demo data
                    itemBuilder: (context, index) {
                      // Demo booking data
                      String type = index % 2 == 0 ? 'Passenger' : 'Cargo';
                      String description = index % 2 == 0 
                          ? '${(index + 1)} passengers to City Center' 
                          : 'Package delivery to Station Road';
                      String status = index == 0 ? 'Active' : 'Completed';
                      
                      Color statusColor = status == 'Active' ? Colors.orange : Colors.green;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: type == 'Passenger' ? Colors.blue.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  type == 'Passenger' ? Icons.person : Icons.local_shipping,
                                  color: type == 'Passenger' ? Colors.blue : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: type == 'Passenger' ? Colors.blue : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}