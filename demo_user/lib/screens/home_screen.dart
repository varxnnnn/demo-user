import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/user_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../services/trip_service.dart';
import '../models/trip.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final LocationService _locationService = LocationService();
  final TripService _tripService = TripService();
  
  // Trip booking state
  bool _isBookingTrip = false;
  String? _currentTripId;
  Stream<Trip>? _tripStream;
  Trip? _currentTrip;
  
  @override
  void initState() {
    super.initState();
    _setupLocationControllers();
    // Automatically get current location when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }
  
  void _setupLocationControllers() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Listen to changes in location provider to update text controllers
    Provider.of<LocationProvider>(context, listen: false).addListener(() {
      if (mounted) {
        setState(() {
          _destinationController.text = locationProvider.destination;
        });
      }
    });
  }
  
  void _getCurrentLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.getCurrentLocation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to get current location: $e')),
      );
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Share App'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              userProvider.logoutUser();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${userProvider.user?.name ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Book a ride to your destination',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Request a Ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Unified Location Selection
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            // Pickup Location
                            GestureDetector(
                              onTap: () {
                                _showLocationPicker(true); // true for pickup
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.my_location, color: Colors.blue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pickup Location',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            locationProvider.pickupLocation.isNotEmpty 
                                                ? locationProvider.pickupLocation 
                                                : 'Tap to select pickup location',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Icon(Icons.swap_vert, color: Colors.grey),
                            const SizedBox(height: 12),
                            // Destination Location
                            GestureDetector(
                              onTap: () {
                                _showLocationPicker(false); // false for destination
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_pin, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Destination',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            locationProvider.destination.isNotEmpty 
                                                ? locationProvider.destination 
                                                : 'Tap to select destination',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.green),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Location suggestions for destination
                      if (locationProvider.predictions.isNotEmpty)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: ListView.builder(
                            itemCount: locationProvider.predictions.length,
                            itemBuilder: (context, index) {
                              final prediction = locationProvider.predictions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.green),
                                title: Text(
                                  prediction.description,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: prediction.secondaryText != null 
                                    ? Text(
                                        prediction.secondaryText!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
                                    : null,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                onTap: () {
                                  locationProvider.selectLocation(prediction);
                                },
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: locationProvider.pickupLat != null && 
                                       locationProvider.pickupLng != null && 
                                       locationProvider.destinationLat != null && 
                                       locationProvider.destinationLng != null
                                  ? () {
                                      Navigator.pushNamed(context, MapScreen.id);
                                    }
                                  : null, // Disable button if locations aren't set
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'View Route',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: locationProvider.pickupLat != null && 
                                       locationProvider.pickupLng != null && 
                                       locationProvider.destinationLat != null && 
                                       locationProvider.destinationLng != null
                                  ? () {
                                      _requestRide();
                                    }
                                  : null, // Disable button if locations aren't set
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Request Ride',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Quick Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickDestinationCard(
                      icon: Icons.home,
                      title: 'Home',
                      subtitle: 'Tap to set',
                      onTap: () {
                        _selectQuickDestination('Home Address');
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildQuickDestinationCard(
                      icon: Icons.work,
                      title: 'Work',
                      subtitle: 'Tap to set',
                      onTap: () {
                        _selectQuickDestination('Office Address');
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildQuickDestinationCard(
                      icon: Icons.shopping_bag,
                      title: 'Market',
                      subtitle: 'Tap to set',
                      onTap: () {
                        _selectQuickDestination('Shopping Center');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ride Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildRideOptionCard(
                      icon: Icons.motorcycle,
                      title: 'Bike',
                      subtitle: 'Affordable rides',
                      price: '₹15/km',
                    ),
                    _buildRideOptionCard(
                      icon: Icons.directions_car,
                      title: 'Car',
                      subtitle: 'Comfortable rides',
                      price: '₹20/km',
                    ),
                    _buildRideOptionCard(
                      icon: Icons.local_taxi,
                      title: 'Taxi',
                      subtitle: 'Premium service',
                      price: '₹25/km',
                    ),
                    _buildRideOptionCard(
                      icon: Icons.train,
                      title: 'Auto',
                      subtitle: 'Quick rides',
                      price: '₹12/km',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDestinationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ride Requested'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your ride has been booked successfully.'),
              const SizedBox(height: 10),
              Text('From: ${Provider.of<LocationProvider>(context, listen: false).pickupLocation}'),
              Text('To: ${Provider.of<LocationProvider>(context, listen: false).destination}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _selectQuickDestination(String destination) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.setDestination(destination);
  }
  
  void _requestRide() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    if (userProvider.user == null ||
        locationProvider.pickupLat == null ||
        locationProvider.pickupLng == null ||
        locationProvider.destinationLat == null ||
        locationProvider.destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set both pickup and destination locations')),
      );
      return;
    }
    
    _bookTrip();
  }
  
  Future<void> _bookTrip() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    setState(() {
      _isBookingTrip = true;
    });
    
    try {
      // Calculate approximate fare (in a real app, this would be calculated based on distance)
      double fare = _calculateFare(locationProvider.pickupLat!, locationProvider.pickupLng!, 
                                  locationProvider.destinationLat!, locationProvider.destinationLng!);
      
      String tripId = await _tripService.createTripRequest(
        userId: userProvider.user!.uid,
        userName: userProvider.user!.name,
        pickupLocation: locationProvider.pickupLocation,
        dropoffLocation: locationProvider.destination,
        pickupLat: locationProvider.pickupLat!,
        pickupLng: locationProvider.pickupLng!,
        dropoffLat: locationProvider.destinationLat!,
        dropoffLng: locationProvider.destinationLng!,
        fare: fare,
      );
      
      setState(() {
        _currentTripId = tripId;
        _tripStream = _tripService.getTripUpdates(tripId) as Stream<Trip>?;
      });
      
      // Show trip status screen
      _showTripStatusModal();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking trip: \$e')),
      );
      setState(() {
        _isBookingTrip = false;
      });
    }
  }
  
  double _calculateFare(double pickupLat, double pickupLng, double dropoffLat, double dropoffLng) {
    // This is a simplified fare calculation
    // In a real app, this would use Google Maps API to calculate distance
    double distance = _calculateDistance(pickupLat, pickupLng, dropoffLat, dropoffLng);
    double baseFare = 20.0; // Base fare
    double perKmRate = 15.0; // Rate per km
    return baseFare + (distance * perKmRate);
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation using haversine formula
    var p = 0.017453292519943295;    // Math.PI / 180
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    
    double distanceInKm = 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
    return distanceInKm.abs();
  }
  
  void _showTripStatusModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return StreamBuilder<Trip?>(
              stream: _tripStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Trip trip = snapshot.data!;
                  _currentTrip = trip;
                  
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Trip',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTripStatusCard(trip),
                        const SizedBox(height: 16),
                        if (trip.status == 'requested')
                          const LinearProgressIndicator(),
                        const SizedBox(height: 16),
                        if (trip.status == 'requested')
                          ElevatedButton(
                            onPressed: () {
                              _cancelTrip();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cancel Trip'),
                          )
                        else if (trip.status == 'accepted')
                          Text(
                            'Driver is coming to pick you up',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          )
                        else if (trip.status == 'driver_arrived')
                          Text(
                            'Driver has arrived',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          )
                        else if (trip.status == 'in_progress')
                          Text(
                            'Trip in progress',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          )
                        else if (trip.status == 'completed')
                          Column(
                            children: [
                              const Text(
                                'Trip Completed!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          )
                        else if (trip.status == 'cancelled')
                          Column(
                            children: [
                              const Text(
                                'Trip Cancelled',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Loading trip status...'),
                        const LinearProgressIndicator(),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildTripStatusCard(Trip trip) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: \${_getStatusDisplayText(trip.status)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(trip.status),
                  ),
                ),
                if (trip.driverName != null) Text('Driver: \${trip.driverName!}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('From: \${trip.pickupLocation}'),
            Text('To: \${trip.dropoffLocation}'),
            const SizedBox(height: 8),
            Text('Fare: ₹\${trip.fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (trip.driverPhone != null) Text('Driver Phone: \${trip.driverPhone!}'),
            if (trip.vehicleNumber != null) Text('Vehicle: \${trip.vehicleNumber!}'),
          ],
        ),
      ),
    );
  }
  
  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'requested':
        return 'Searching for drivers';
      case 'accepted':
        return 'Driver accepted';
      case 'driver_arrived':
        return 'Driver arrived';
      case 'in_progress':
        return 'In trip';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
      case 'driver_arrived':
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _cancelTrip() async {
    if (_currentTripId != null) {
      try {
        await _tripService.cancelTrip(_currentTripId!);
        setState(() {
          _isBookingTrip = false;
          _currentTripId = null;
          _tripStream = null;
          _currentTrip = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling trip: \$e')),
        );
      }
    }
  }
  
  void _showLocationPicker(bool isPickup) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPickup ? 'Select Pickup Location' : 'Select Destination',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for places...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        locationProvider.searchLocations(value);
                      } else {
                        locationProvider.clearPredictions();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<PlacePrediction>>(
                      stream: Stream.value(locationProvider.predictions),
                      builder: (context, snapshot) {
                        if (locationProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (locationProvider.predictions.isEmpty) {
                          return const Center(
                            child: Text(
                              'Start typing to search for locations',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: locationProvider.predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = locationProvider.predictions[index];
                            return ListTile(
                              leading: Icon(
                                isPickup ? Icons.my_location : Icons.location_pin,
                                color: isPickup ? Colors.blue : Colors.green,
                              ),
                              title: Text(
                                prediction.description,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: prediction.secondaryText != null 
                                  ? Text(
                                      prediction.secondaryText!,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    )
                                  : null,
                              onTap: () async {
                                await locationProvider.selectLocation(prediction);
                                Navigator.of(context).pop();
                                
                                // Show confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isPickup 
                                          ? 'Pickup location set to: \${locationProvider.pickupLocation}'
                                          : 'Destination set to: \${locationProvider.destination}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}