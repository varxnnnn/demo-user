import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/trips_provider.dart';
import '../models/trip_model.dart';
import 'trip_details_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    // Fetch trip history when tab is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      
      if (userProvider.user != null) {
        tripsProvider.fetchUserTrips(userProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final tripsProvider = Provider.of<TripsProvider>(context);

    if (userProvider.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trip History'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your trip history'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _buildHistoryContent(tripsProvider),
    );
  }

  Widget _buildHistoryContent(TripsProvider tripsProvider) {
    if (tripsProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tripsProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${tripsProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                if (userProvider.user != null) {
                  tripsProvider.fetchUserTrips(userProvider.user!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (tripsProvider.trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[300]!,
            ),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600]!,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400]!,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user != null) {
          await Provider.of<TripsProvider>(context, listen: false)
              .fetchUserTrips(userProvider.user!.uid);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tripsProvider.trips.length,
        itemBuilder: (context, index) {
          final trip = tripsProvider.trips[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailsScreen(trip: trip),
                ),
              );
            },
            child: _buildTripCard(trip),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trip type and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTripTypeIcon(trip.tripType),
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTripTypeName(trip.tripType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(trip.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Locations
            _buildLocationRow(
              icon: Icons.location_on,
              color: Colors.blue,
              location: trip.pickupLocation.formattedAddress,
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              icon: Icons.location_on,
              color: Colors.green,
              location: trip.dropoffLocation.formattedAddress,
            ),
            const SizedBox(height: 12),

            // Divider
            Divider(height: 1, color: Colors.grey[300]!),
            const SizedBox(height: 12),

            // Trip details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${trip.distance.toStringAsFixed(1)} km',
                ),
                _buildDetailItem(
                  icon: Icons.schedule,
                  label: 'Duration',
                  value: '${trip.estimatedDuration} min',
                ),
                _buildDetailItem(
                  icon: Icons.attach_money,
                  label: 'Fare',
                  value: '${trip.fare.toStringAsFixed(0)} ৳',
                ),
              ],
            ),

            if (trip.tripType == TripType.objectTransport) ...[
              const SizedBox(height: 12),
              _buildObjectDetails(trip.transportDetails),
            ] else ...[
              const SizedBox(height: 12),
              _buildPassengerDetails(trip.transportDetails),
            ],

            const SizedBox(height: 12),

            // Date
            Text(
              'Created: ${_formatDate(trip.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600]!,
              ),
            ),

            // Driver info if assigned
            if (trip.driverName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Driver: ${trip.driverName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600]!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]!, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600]!,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectDetails(TransportDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.objectType != null)
            Text(
              'Object: ${_getObjectTypeName(details.objectType!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (details.objectDescription != null && details.objectDescription!.isNotEmpty)
            Text('Description: ${details.objectDescription}'),
          if (details.weight != null)
            Text('Weight: ${details.weight} kg'),
          if (details.isFragile == true)
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Fragile',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetails(TransportDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers: ${details.numberOfPassengers ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (details.passengerNames != null && details.passengerNames!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.passengerNames!
                    .map((name) => Text('• $name'))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTripTypeIcon(TripType type) {
    switch (type) {
      case TripType.objectTransport:
        return Icons.inventory;
      case TripType.peopleTransport:
        return Icons.group;
    }
  }

  String _getTripTypeName(TripType type) {
    switch (type) {
      case TripType.objectTransport:
        return 'Object Transport';
      case TripType.peopleTransport:
        return 'People Transport';
    }
  }

  String _getObjectTypeName(ObjectType type) {
    switch (type) {
      case ObjectType.document:
        return 'Document';
      case ObjectType.package:
        return 'Package';
      case ObjectType.furniture:
        return 'Furniture';
      case ObjectType.electronics:
        return 'Electronics';
      case ObjectType.clothing:
        return 'Clothing';
      case ObjectType.food:
        return 'Food';
      case ObjectType.medical:
        return 'Medical';
      case ObjectType.other:
        return 'Other';
    }
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.requested:
        return Colors.orange;
      case TripStatus.accepted:
        return Colors.blue;
      case TripStatus.driver_arrived:
        return Colors.purple;
      case TripStatus.in_progress:
        return Colors.indigo;
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.requested:
        return 'Requested';
      case TripStatus.accepted:
        return 'Accepted';
      case TripStatus.driver_arrived:
        return 'Arrived';
      case TripStatus.in_progress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}