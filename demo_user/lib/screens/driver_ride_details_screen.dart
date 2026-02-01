import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRideDetailsScreen extends StatefulWidget {
  static const String id = '/driver-ride-details';

  final String? rideId;

  const DriverRideDetailsScreen({Key? key, this.rideId}) : super(key: key);

  @override
  _DriverRideDetailsScreenState createState() => _DriverRideDetailsScreenState();
}

class _DriverRideDetailsScreenState extends State<DriverRideDetailsScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  DocumentSnapshot? _rideSnapshot;
  bool _isLoading = true;
  String _rideStatus = 'confirmed';
  String? _rideId;

  @override
  void initState() {
    super.initState();
    _rideId = ModalRoute.of(context)?.settings.arguments as String?;
    if (widget.rideId != null) {
      _rideId = widget.rideId;
    }
    _loadRideDetails();
  }

  Future<void> _loadRideDetails() async {
    if (_rideId == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('rides').doc(_rideId);
      _rideSnapshot = await docRef.get();
      
      setState(() {
        _isLoading = false;
        _rideStatus = _rideSnapshot!['status'] ?? 'confirmed';
      });

      _updateMap();
    } catch (e) {
      print('Error loading ride details: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ride details: $e')),
      );
    }
  }

  void _updateMap() {
    if (_rideSnapshot == null) return;

    final pickupLat = _rideSnapshot!['pickupLat'];
    final pickupLng = _rideSnapshot!['pickupLng'];
    final destLat = _rideSnapshot!['destinationLat'];
    final destLng = _rideSnapshot!['destinationLng'];

    if (pickupLat != null && pickupLng != null && destLat != null && destLng != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pickupLat, pickupLng),
            infoWindow: const InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(destLat, destLng),
            infoWindow: const InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }
  }

  void _updateRideStatus(String newStatus) async {
    if (_rideId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(_rideId)
          .update({
        'status': newStatus,
        'driverStatusChangedAt': FieldValue.serverTimestamp(),
      });

      // Update driver's status if needed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String driverStatus = 'online';
        if (newStatus == 'completed') {
          driverStatus = 'online';
        } else if (newStatus == 'picked_up') {
          driverStatus = 'driving';
        }
        
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({'status': driverStatus});
      }

      setState(() {
        _rideStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      if (newStatus == 'completed') {
        // Navigate back after completion
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating ride status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ride Details'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_rideSnapshot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ride Details'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Ride not found')),
      );
    }

    final rideData = _rideSnapshot!.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _getInitialCameraPosition(rideData),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ride Information
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride ID and Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ride #${_rideId?.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rideData['bookingType'] == 'person' ? Colors.blue[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rideData['bookingType'] == 'person' ? '👤 Person' : '📦 Cargo',
                            style: TextStyle(
                              color: rideData['bookingType'] == 'person' ? Colors.blue[800] : Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pickup Location
                    _buildInfoCard(
                      'Pickup Location',
                      rideData['pickupLocation'] ?? 'N/A',
                      Icons.location_on,
                      Colors.blue,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Destination
                    _buildInfoCard(
                      'Destination',
                      rideData['destination'] ?? 'N/A',
                      Icons.flag,
                      Colors.red,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Distance and Duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Distance',
                            rideData['distance'] ?? 'N/A',
                            Icons.straighten,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Duration',
                            rideData['duration'] ?? 'N/A',
                            Icons.access_time,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Fare Estimate
                    _buildInfoCard(
                      'Fare Estimate',
                      rideData['fareEstimate'] ?? 'N/A',
                      Icons.monetization_on,
                      Colors.teal,
                    ),
                    
                    // Cargo specific details if applicable
                    if (rideData['bookingType'] == 'cargo') ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Parcel Type',
                        rideData['parcelType'] ?? 'N/A',
                        Icons.local_shipping,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Material',
                        rideData['materialType'] ?? 'N/A',
                        Icons.category,
                        Colors.brown,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Weight',
                        '${rideData['weight']} kg',
                        Icons.scale,
                        Colors.amber,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: $_rideStatus.toUpperCase()',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons based on status
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_rideStatus) {
      case 'requested':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'picked_up':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_rideStatus) {
      case 'requested':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'picked_up':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildActionButtons() {
    switch (_rideStatus) {
      case 'confirmed':
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _updateRideStatus('picked_up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'MARK AS PICKED UP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'picked_up':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _updateRideStatus('completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'MARK AS COMPLETED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _showCancelConfirmation(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'CANCEL RIDE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              _updateRideStatus('cancelled');
              Navigator.pop(context);
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  CameraPosition _getInitialCameraPosition(Map<String, dynamic> rideData) {
    final pickupLat = rideData['pickupLat'];
    final pickupLng = rideData['pickupLng'];
    final destLat = rideData['destinationLat'];
    final destLng = rideData['destinationLng'];

    if (pickupLat != null && pickupLng != null) {
      return CameraPosition(
        target: LatLng(pickupLat, pickupLng),
        zoom: 14,
      );
    } else if (destLat != null && destLng != null) {
      return CameraPosition(
        target: LatLng(destLat, destLng),
        zoom: 14,
      );
    } else {
      return const CameraPosition(
        target: LatLng(40.7128, -74.0060),
        zoom: 12,
      );
    }
  }
}