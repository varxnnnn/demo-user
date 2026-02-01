import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ride_request_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_ride_request.dart';
import 'create_ride_screen.dart';
import 'chat_negotiation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  bool _hasActiveTrip = false;
  String _currentTripStatus = 'waiting';
  
  // Ride requests
  List<UserRideRequest> _rideRequests = [];
  Stream<List<UserRideRequest>>? _rideRequestsStream;
  int _activeTab = 0; // 0: Available, 1: Active, 2: Completed

  @override
  void initState() {
    super.initState();
    _initializeRideRequests();
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
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
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
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
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
        // Status Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
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
                  
                  // Stats
                  Row(
                    children: [
                      _buildStatCard('Today', '12', '₹2,450', Icons.directions_car),
                      _buildStatCard('Week', '45', '₹8,900', Icons.calendar_today),
                      _buildStatCard('Rating', '4.8', '⭐ 4.8', Icons.star),
                    ],
                  ),
                  
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
            ],
          ),
        ),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Tab Headers
              Container(
                height: 50,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Available', Icons.playlist_add_check),
                    _buildTab(1, 'Active', Icons.navigation),
                    _buildTab(2, 'Completed', Icons.check_circle),
                  ],
                ),
              ),

              // Tab Content
              SizedBox(
                height: 400,
                child: _activeTab == 0
                    ? _buildAvailableRides()
                    : _activeTab == 1
                        ? _buildActiveRides()
                        : _buildCompletedRides(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _activeTab == index ? Colors.green.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: _activeTab == index ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
    return _buildEmptyState('No active trips', Icons.navigation);
  }

  Widget _buildCompletedRides() {
    return _buildEmptyState('No completed trips yet', Icons.check_circle);
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
    return Container(
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
      final rideRequestService = RideRequestService();
      await rideRequestService.acceptRideRequest(request.id, _getDriverId());
      
      setState(() {
        _rideRequests.remove(request);
        _hasActiveTrip = true;
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
}