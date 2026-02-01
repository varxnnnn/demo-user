import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/location_provider.dart';

class BookRideScreen extends StatelessWidget {
  static const String id = '/book-ride';

  const BookRideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Ride'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Start:', locationProvider.pickupLocation),
                  const SizedBox(height: 8),
                  _buildInfoRow('Destination:', locationProvider.destination),
                  const SizedBox(height: 8),
                  if (locationProvider.distanceText.isNotEmpty)
                    _buildInfoRow('Distance:', locationProvider.distanceText),
                  if (locationProvider.durationText.isNotEmpty)
                    _buildInfoRow('Estimated Time:', locationProvider.durationText),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Booking Type Selection
            const Text(
              'Select Booking Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToPersonBooking(context, locationProvider),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Person',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToCargoBooking(context, locationProvider),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 40,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cargo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToPersonBooking(BuildContext context, LocationProvider locationProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonBookingScreen(locationProvider: locationProvider),
      ),
    );
  }

  void _navigateToCargoBooking(BuildContext context, LocationProvider locationProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargoBookingScreen(locationProvider: locationProvider),
      ),
    );
  }
}

class PersonBookingScreen extends StatelessWidget {
  final LocationProvider locationProvider;

  const PersonBookingScreen({Key? key, required this.locationProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Booking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
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
                  const SizedBox(height: 12),
                  _buildInfoRow('Passenger Count:', '1'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Luggage:', 'Standard'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Distance:', locationProvider.distanceText),
                  const SizedBox(height: 8),
                  _buildInfoRow('Duration:', locationProvider.durationText),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price Estimation
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
                    'Price Estimate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Estimated Fare:', '\$15 - \$25'),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Confirm Booking Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _confirmBooking(context, 'person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'CONFIRM BOOKING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking(BuildContext context, String bookingType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('rides').add({
        'userId': user.uid,
        'bookingType': bookingType,
        'passengerCount': 1,
        'luggage': 'Standard',
        'pickupLocation': locationProvider.pickupLocation,
        'destination': locationProvider.destination,
        'pickupLat': locationProvider.pickupLat,
        'pickupLng': locationProvider.pickupLng,
        'destinationLat': locationProvider.destinationLat,
        'destinationLng': locationProvider.destinationLng,
        'distance': locationProvider.distanceText,
        'duration': locationProvider.durationText,
        'fareEstimate': '\$15 - \$25',
        'status': 'requested',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now(),
      });

      // Show waiting screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .map((snapshot) => snapshot.docs.first),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final ride = snapshot.data!;
                final rideStatus = ride['status'] ?? 'requested';
                
                if (rideStatus == 'confirmed') {
                  // Driver has accepted the ride
                  Future.delayed(Duration.zero, () {
                    Navigator.of(context).pop(); // Close waiting dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    Navigator.of(context).pushReplacementNamed('/main'); // Navigate to main screen
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Driver confirmed your ride!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                } else if (rideStatus == 'cancelled') {
                  // Ride was cancelled
                  Future.delayed(Duration.zero, () {
                    Navigator.of(context).pop(); // Close waiting dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    
                    // Show cancellation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ride was cancelled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  });
                }

                return AlertDialog(
                  title: const Text('Waiting for Driver'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your ride request has been sent.'),
                      const SizedBox(height: 8),
                      Text('Status: $rideStatus'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text('Driver will accept your request shortly...'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCEL REQUEST'),
                    ),
                  ],
                );
              } else {
                return AlertDialog(
                  title: const Text('Waiting for Driver'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your ride request has been sent.'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Driver will accept your request shortly...'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCEL REQUEST'),
                    ),
                  ],
                );
              }
            },
          );
        },
      );
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class CargoBookingScreen extends StatelessWidget {
  final LocationProvider locationProvider;

  const CargoBookingScreen({Key? key, required this.locationProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final parcelTypeController = TextEditingController();
    final materialController = TextEditingController();
    final weightController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Booking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cargo Details Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cargo Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Parcel Type
                    const Text(
                      'Parcel Type *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: parcelTypeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Documents, Electronics, Fragile Items',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Material Type
                    const Text(
                      'Material Type *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: materialController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Plastic, Glass, Metal, Paper',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight
                    const Text(
                      'Weight (kg) *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter weight in kg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Options
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Fragile
                    CheckboxListTile(
                      title: const Text('Fragile Item'),
                      value: false,
                      onChanged: (bool? value) {},
                    ),
                    
                    // Insurance
                    CheckboxListTile(
                      title: const Text('Insurance Coverage'),
                      value: false,
                      onChanged: (bool? value) {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Price Estimation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Estimate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Distance:', locationProvider.distanceText),
                    const SizedBox(height: 8),
                    _buildInfoRow('Weight:', weightController.text),
                    const SizedBox(height: 8),
                    _buildInfoRow('Estimated Fare:', '\$20 - \$40'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Confirm Booking Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (parcelTypeController.text.isEmpty ||
                        materialController.text.isEmpty ||
                        weightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _confirmBooking(
                      context,
                      'cargo',
                      parcelTypeController.text,
                      materialController.text,
                      weightController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'CONFIRM BOOKING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking(
    BuildContext context,
    String bookingType,
    String parcelType,
    String materialType,
    String weight,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('rides').add({
        'userId': user.uid,
        'bookingType': bookingType,
        'parcelType': parcelType,
        'materialType': materialType,
        'weight': weight,
        'fragile': false, // Will be updated if user selects fragile
        'insurance': false, // Will be updated if user selects insurance
        'pickupLocation': locationProvider.pickupLocation,
        'destination': locationProvider.destination,
        'pickupLat': locationProvider.pickupLat,
        'pickupLng': locationProvider.pickupLng,
        'destinationLat': locationProvider.destinationLat,
        'destinationLng': locationProvider.destinationLng,
        'distance': locationProvider.distanceText,
        'duration': locationProvider.durationText,
        'fareEstimate': '\$20 - \$40',
        'status': 'requested',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now(),
      });

      // Show waiting screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .map((snapshot) => snapshot.docs.first),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final ride = snapshot.data!;
                final rideStatus = ride['status'] ?? 'requested';
                
                if (rideStatus == 'confirmed') {
                  // Driver has accepted the ride
                  Future.delayed(Duration.zero, () {
                    Navigator.of(context).pop(); // Close waiting dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    Navigator.of(context).pushReplacementNamed('/main'); // Navigate to main screen
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Driver confirmed your ride!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                } else if (rideStatus == 'cancelled') {
                  // Ride was cancelled
                  Future.delayed(Duration.zero, () {
                    Navigator.of(context).pop(); // Close waiting dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    
                    // Show cancellation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ride was cancelled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  });
                }

                return AlertDialog(
                  title: const Text('Waiting for Driver'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your cargo ride request has been sent.'),
                      const SizedBox(height: 8),
                      Text('Status: $rideStatus'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text('Driver will accept your request shortly...'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCEL REQUEST'),
                    ),
                  ],
                );
              } else {
                return AlertDialog(
                  title: const Text('Waiting for Driver'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your cargo ride request has been sent.'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Driver will accept your request shortly...'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCEL REQUEST'),
                    ),
                  ],
                );
              }
            },
          );
        },
      );
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}