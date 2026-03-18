import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ride_request_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_ride_request.dart';
import 'chat_negotiation_screen.dart';
import 'driver_map_view.dart';
import 'driver_trip_details_screen.dart';
import 'verification_entry_screen.dart';
import '../../models/trip.dart';
import 'trip_route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  // ignore: unused_field
  bool _hasActiveTrip = false;
  // ignore: unused_field
  String _currentTripStatus = 'waiting';
  
  // Ride requests
  List<UserRideRequest> _rideRequests = [];
  Stream<List<UserRideRequest>>? _rideRequestsStream;
  int _activeTab = 0; // 0: Available, 1: Active

  @override
  void initState() {
    super.initState();
    _checkCurrentDriverStatus();
    _initializeRideRequests();
  }
  
  void _checkCurrentDriverStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;
    
    if (driverId != null) {
      try {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .get();
            
        if (driverDoc.exists) {
          final status = driverDoc.data()?['onlineStatus'] ?? 'offline';
          setState(() {
            _isOnline = status == 'online';
          });
        }
      } catch (e) {
        print('Error fetching driver status: $e');
      }
    }
  }

  @override
  void dispose() {
    _rideRequestsStream?.drain();
    super.dispose();
  }

  void _initializeRideRequests() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;
    
    if (driverId != null) {
      // Listen for ride requests for this driver
      _rideRequestsStream = RideRequestService().getRideRequestsForDriver(driverId);
      _rideRequestsStream!.listen((requests) {
        if (mounted) {
          setState(() {
            _rideRequests = requests;
          });
        }
      });
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _startAcceptingRides();
    } else {
      _stopAcceptingRides();
    }
  }

  void _startAcceptingRides() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;
    
    if (driverId != null) {
      // Update driver status in Firestore
      authService.saveDriverData(driverId, {
        'onlineStatus': 'online',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _stopAcceptingRides() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.currentUser?.uid;
    
    if (driverId != null) {
      // Update driver status in Firestore
      authService.saveDriverData(driverId, {
        'onlineStatus': 'offline',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
                    backgroundColor: const Color(0xFFF5F5F5),
      body: _isOnline ? _buildOnlineView() : _buildOfflineView(),
    );
  }

  Widget _buildOfflineView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFF4A148C),
            Color(0xFF311B92),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.power_settings_new,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You\'re Offline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF311B92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go online to start receiving ride requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _toggleOnlineStatus,
                    icon: const Icon(Icons.power),
                    label: const Text('Go Online'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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

  Widget _buildOnlineView() {
    return Column(
      children: [
        // Tabs at the top
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              // Tab Headers
              Container(
                height: 65,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Available', Icons.playlist_add_check),
                    _buildTab(1, 'Active', Icons.navigation),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Content area for each tab
        Expanded(
          child: _activeTab == 0
              ? _buildAvailableContent()  // Map + available rides
              : _buildActiveContent(),   // Active rides
        ),
      ],
    );
  }
  
  // Build content for Available tab (Available Rides only)
  Widget _buildAvailableContent() {
    return Column(
      children: [
        // Status bar with online indicator and offline button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              // Online Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Go Offline Button
              ElevatedButton.icon(
                onPressed: _toggleOnlineStatus,
                icon: const Icon(Icons.power_off),
                label: const Text('Go Offline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  minimumSize: const Size(120, 36),
                ),
              ),
            ],
          ),
        ),
        
        // Available rides list
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildAvailableRides(),
          ),
        ),
      ],
    );
  }
  
  // Build content for Active tab
  Widget _buildActiveContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildActiveRides(),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _activeTab == index ? Colors.green.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: _activeTab == index ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: _activeTab == index ? Colors.green : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: _activeTab == index ? Colors.green : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildAvailableRides() {
    if (_rideRequests.isEmpty) {
      return _buildEmptyState('No ride requests available', Icons.drive_eta);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _rideRequests.length,
      itemBuilder: (context, index) {
        final request = _rideRequests[index];
        return _buildRideRequestCard(request);
      },
    );
  }

  Widget _buildActiveRides() {
    final driverId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    
    if (driverId == null) {
      return _buildEmptyState('No active trips', Icons.navigation);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('activeTrips')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No active trips', Icons.navigation);
        }

        final activeTrips = snapshot.data!.docs;

        return ListView.builder(
          itemCount: activeTrips.length,
          itemBuilder: (context, index) {
            final tripData = activeTrips[index].data() as Map<String, dynamic>;
            return _buildActiveRideCard(
              tripId: (tripData['tripId'] ?? '').toString(),
              userName: (tripData['userName'] ?? 'Unknown').toString(),
              pickupLocation: (tripData['pickupLocation'] ?? '').toString(),
              dropoffLocation: (tripData['dropoffLocation'] ?? '').toString(),
              status: (tripData['status'] ?? 'waiting').toString(),
              offeredPrice: (tripData['offeredPrice'] ?? 0.0).toDouble(),
              pickupLat: (tripData['pickupLat'] as num?)?.toDouble(),
              pickupLng: (tripData['pickupLng'] as num?)?.toDouble(),
              dropoffLat: (tripData['dropoffLat'] as num?)?.toDouble(),
              dropoffLng: (tripData['dropoffLng'] as num?)?.toDouble(),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveRideCard({
    required String tripId,
    required String userName,
    required String pickupLocation,
    required String dropoffLocation,
    required String status,
    required double offeredPrice,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6A1B9A),
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Locations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.location_on, 'PICKUP', pickupLocation),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'DROPOFF', dropoffLocation),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.currency_rupee, 'FARE', '₹${offeredPrice.toStringAsFixed(0)}'),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Verify Button (shown when driver is at pickup)
                if (status == 'en_route' || status == 'arrived_at_pickup')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show verification screen
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationEntryScreen(
                              tripId: tripId,
                              userName: userName,
                              pickupLocation: pickupLocation,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ride in progress! Head to destination'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('VERIFY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                
                // Navigate Button (shown for all statuses)
                if (status != 'arrived_at_pickup')
                  const SizedBox(width: 12),
                if (status != 'arrived_at_pickup')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to trip details screen
                        final trip = Trip(
                          id: tripId,
                          userId: '', // Will be populated from Firestore
                          userName: userName,
                          pickupLocation: pickupLocation,
                          dropoffLocation: dropoffLocation,
                          pickupLat: pickupLat ?? 0.0,
                          pickupLng: pickupLng ?? 0.0,
                          dropoffLat: dropoffLat ?? 0.0,
                          dropoffLng: dropoffLng ?? 0.0,
                          fare: offeredPrice,
                          status: status,
                          createdAt: null,
                          driverId: '', // Will be populated from Firestore
                          driverName: '', // Will be populated from Firestore
                          driverPhone: '', // Will be populated from Firestore
                          vehicleNumber: '', // Will be populated from Firestore
                          estimatedArrivalTime: null, // Will be populated from Firestore
                          acceptedAt: null, // Will be populated from Firestore
                          driverArrivedAt: null, // Will be populated from Firestore
                          startedAt: null, // Will be populated from Firestore
                          completedAt: null, // Will be populated from Firestore
                          cancelledAt: null, // Will be populated from Firestore
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverTripDetailsScreen(trip: trip),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_car),
                      label: const Text('NAVIGATE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rides will appear here once accepted',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(UserRideRequest request) {
    return GestureDetector(
      onTap: () {
        if (request.pickupLat != null &&
            request.pickupLng != null &&
            request.dropoffLat != null &&
            request.dropoffLng != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripRouteScreen(
                pickupLat: request.pickupLat!,
                pickupLng: request.pickupLng!,
                dropoffLat: request.dropoffLat!,
                dropoffLng: request.dropoffLng!,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6A1B9A),
                    child: Text(
                      request.userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${request.userRating}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(request.urgency),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${request.urgency.toUpperCase()} • ${_getTimeAgo(request.requestedAt)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ride Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.location_on, 'PICKUP', request.pickupLocation),
                  _buildDetailRow(Icons.location_on, 'DROPOFF', request.dropoffLocation),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.directions_car, 'DISTANCE', '${request.distance.toStringAsFixed(1)} km'),
                  _buildDetailRow(Icons.currency_rupee, 'OFFERED', '₹${request.offeredPrice.toStringAsFixed(0)}'),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptRide(request),
                      icon: const Icon(Icons.check),
                      label: const Text('ACCEPT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _negotiateRide(request),
                      icon: const Icon(Icons.chat),
                      label: const Text('NEGOTIATE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _rejectRide(request),
                    icon: const Icon(Icons.close),
                    iconSize: 24,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _acceptRide(UserRideRequest request) async {
    try {
      // Get driver name from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final driverName = authService.currentUser?.displayName ?? 'Driver';
      
      final rideRequestService = RideRequestService();
      // Pass the full request object and let service handle activeTrips creation
      await rideRequestService.acceptRideRequest(request, _getDriverId(), driverName);

      setState(() {
        _rideRequests.remove(request);
        _hasActiveTrip = true;
        _activeTab = 1; // Switch to active tab
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectRide(UserRideRequest request) async {
    try {
      final rideRequestService = RideRequestService();
      await rideRequestService.rejectRideRequest(request.id);
      
      setState(() {
        _rideRequests.remove(request);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _negotiateRide(UserRideRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatNegotiationScreen(
          rideRequest: request,
        ),
      ),
    );
  }

  String _getDriverId() {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUser?.uid ?? '';
  }

  void _openNavigationToLocation(double lat, double lng) {
    // This would typically open Google Maps or another navigation app
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $lat, $lng'),
      ),
    );
  }
}