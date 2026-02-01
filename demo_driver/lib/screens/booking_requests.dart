import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/capacity_provider.dart';
import '../models/vehicle_capacity.dart';

class BookingRequestsScreen extends StatefulWidget {
  static const String id = 'booking_requests';

  const BookingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  // Demo booking requests data
  List<BookingRequest> demoRequests = [
    BookingRequest(
      id: 'req1',
      type: 'passenger',
      passengerCount: 2,
      cargoWeight: 0.0,
      canUseSeats: false,
      cargoType: 'parcel',
      pickupLocation: 'Main Street, Downtown',
      destination: 'Central Park, Uptown',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    BookingRequest(
      id: 'req2',
      type: 'cargo',
      passengerCount: 0,
      cargoWeight: 5.0,
      canUseSeats: true,
      cargoType: 'parcel',
      pickupLocation: 'Station Road, Westside',
      destination: 'Airport, Eastside',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    BookingRequest(
      id: 'req3',
      type: 'cargo',
      passengerCount: 0,
      cargoWeight: 0.0,
      canUseSeats: false,
      cargoType: 'document',
      pickupLocation: 'University Campus',
      destination: 'Government Office',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CapacityProvider>(
        builder: (context, capacityProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'New Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Capacity Overview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Capacity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              capacityProvider.currentCapacity != null
                                  ? '${capacityProvider.currentCapacity!.availableSeats} seats, ${capacityProvider.currentCapacity!.availableCargoKg} kg cargo'
                                  : 'Loading...',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Booking Requests List
                Expanded(
                  child: ListView.builder(
                    itemCount: demoRequests.length,
                    itemBuilder: (context, index) {
                      final request = demoRequests[index];
                      final validation = capacityProvider.simulateBookingValidation(request);
                      
                      Color cardColor = validation['canAccept'] == true
                          ? Colors.green.shade50
                          : Colors.red.shade50;
                      Color borderColor = validation['canAccept'] == true
                          ? Colors.green.shade200
                          : Colors.red.shade200;
                      Color textColor = validation['canAccept'] == true
                          ? Colors.green.shade800
                          : Colors.red.shade800;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: cardColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Request Type and Details
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: request.type == 'passenger' 
                                            ? Colors.blue.shade100 
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        request.type == 'passenger' 
                                            ? Icons.person 
                                            : Icons.local_shipping,
                                        color: request.type == 'passenger' 
                                            ? Colors.blue 
                                            : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.type.toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: request.type == 'passenger' 
                                                  ? Colors.blue.shade800 
                                                  : Colors.orange.shade800,
                                            ),
                                          ),
                                          Text(
                                            request.type == 'passenger'
                                                ? '${request.passengerCount} passengers'
                                                : request.cargoWeight <= 0 || request.cargoType == 'document'
                                                    ? 'Documents/Certificates'
                                                    : '${request.cargoWeight} kg cargo${request.canUseSeats ? ' (seats OK)' : ''}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: validation['canAccept'] == true
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: validation['canAccept'] == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      child: Text(
                                        validation['canAccept'] == true ? 'ACCEPT' : 'LIMIT',
                                        style: TextStyle(
                                          color: validation['canAccept'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Locations
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From: ${request.pickupLocation}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            'To: ${request.destination}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Validation Reason
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    validation['reason'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Reject booking
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Booking rejected'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: validation['canAccept'] == true
                                            ? () async {
                                                try {
                                                  await capacityProvider.acceptBooking(request);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Booking accepted!'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: validation['canAccept'] == true
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        child: Text(validation['canAccept'] == true 
                                            ? 'Accept' 
                                            : 'Insufficient Capacity'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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