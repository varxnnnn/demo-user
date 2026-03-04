import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride_completion.dart';
import '../../services/pooling_algorithm_service.dart';

class MultiRideDriverScreen extends StatefulWidget {
  final String driverId;
  final PooledRideGroup pooledRideGroup;

  const MultiRideDriverScreen({
    Key? key,
    required this.driverId,
    required this.pooledRideGroup,
  }) : super(key: key);

  @override
  State<MultiRideDriverScreen> createState() => _MultiRideDriverScreenState();
}

class _MultiRideDriverScreenState extends State<MultiRideDriverScreen> {
  late PoolingAlgorithmService _poolingService;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  late List<String> _currentPickupOrder;
  late List<String> _currentDropoffOrder;
  final Set<String> _pickedUpUsers = {};
  final Set<String> _droppedOffUsers = {};

  int _currentPickupIndex = 0;
  int _currentDropoffIndex = 0;

  @override
  void initState() {
    super.initState();
    _poolingService = PoolingAlgorithmService();
    _currentPickupOrder = List.from(widget.pooledRideGroup.pickupOrder);
    _currentDropoffOrder = List.from(widget.pooledRideGroup.dropoffOrder);
  }

  Future<void> _markUserAsPickedUp() async {
    if (_currentPickupIndex >= _currentPickupOrder.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All passengers picked up!')),
      );
      return;
    }

    final userId = _currentPickupOrder[_currentPickupIndex];

    try {
      await _poolingService.markUserPickedUp(
        poolingKey: widget.pooledRideGroup.poolingKey,
        userId: userId,
      );

      setState(() {
        _pickedUpUsers.add(userId);
        _currentPickupIndex++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userId picked up!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markUserAsDroppedOff() async {
    if (_currentDropoffIndex >= _currentDropoffOrder.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All passengers dropped off!')),
      );
      return;
    }

    final userId = _currentDropoffOrder[_currentDropoffIndex];

    try {
      await _poolingService.markUserDroppedOff(
        poolingKey: widget.pooledRideGroup.poolingKey,
        userId: userId,
      );

      setState(() {
        _droppedOffUsers.add(userId);
        _currentDropoffIndex++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userId dropped off!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Check if ride is complete
      if (_droppedOffUsers.length == widget.pooledRideGroup.userIds.length) {
        _completePooledRide();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completePooledRide() async {
    try {
      await _poolingService.completePooledRide(
        poolingKey: widget.pooledRideGroup.poolingKey,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pooled ride completed!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pooled Ride (${widget.pooledRideGroup.userIds.length} passengers)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Pooling Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pooled Ride Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Passengers: ${widget.pooledRideGroup.userIds.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Pool Discount: ${(widget.pooledRideGroup.poolDiscount * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pickup Order: ${_currentPickupOrder.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dropoff Order: ${_currentDropoffOrder.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passenger Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passenger Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.pooledRideGroup.userIds.map((userId) {
                    final isPickedUp = _pickedUpUsers.contains(userId);
                    final isDroppedOff = _droppedOffUsers.contains(userId);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isDroppedOff
                                ? Icons.check_circle
                                : isPickedUp
                                    ? Icons.directions_run
                                    : Icons.person,
                            color: isDroppedOff
                                ? Colors.green
                                : isPickedUp
                                    ? Colors.orange
                                    : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userId,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDroppedOff
                                    ? Colors.green
                                    : isPickedUp
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            isDroppedOff
                                ? 'Dropped'
                                : isPickedUp
                                    ? 'Picked Up'
                                    : 'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDroppedOff
                                  ? Colors.green
                                  : isPickedUp
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPickupIndex < widget.pooledRideGroup.userIds.length
                        ? _markUserAsPickedUp
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark Picked Up'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentDropoffIndex < widget.pooledRideGroup.userIds.length
                        ? _markUserAsDroppedOff
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark Dropped Off'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Individual Fares',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      ...widget.pooledRideGroup.individualFares.entries
                          .map((e) => Text(
                                '${e.key}: ₹${e.value.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
