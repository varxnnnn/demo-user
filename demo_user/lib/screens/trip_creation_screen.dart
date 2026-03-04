import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/trips_provider.dart';
import '../models/trip_model.dart';
import 'searching_for_driver_screen.dart';

class TripCreationScreen extends StatefulWidget {
  static const String id = 'trip_creation_screen';
  
  final String pickupLocation;
  final String destination;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final bool isCurrentRide;
  
  const TripCreationScreen({
    Key? key,
    required this.pickupLocation,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    this.isCurrentRide = true,
  }) : super(key: key);

  @override
  State<TripCreationScreen> createState() => _TripCreationScreenState();
}

class _TripCreationScreenState extends State<TripCreationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _objectDescriptionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _specialInstructionsController = TextEditingController();
  final TextEditingController _passengerCountController = TextEditingController();
  
  // State variables
  TripType _selectedTripType = TripType.objectTransport;
  ObjectType? _selectedObjectType;
  bool _isFragile = false;
  int _passengerCount = 1;
  List<String> _passengerNames = [''];
  
  @override
  void dispose() {
    _objectDescriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _specialInstructionsController.dispose();
    _passengerCountController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    // Set up the locations in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Create Location models from widget parameters
      final pickupLocation = Location(
        latitude: widget.pickupLat,
        longitude: widget.pickupLng,
        formattedAddress: widget.pickupLocation,
        placeId: 'pickup_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      final dropoffLocation = Location(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
        formattedAddress: widget.destination,
        placeId: 'dropoff_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Set both model-based and legacy location fields
      locationProvider.setPickupLocationModel(pickupLocation);
      locationProvider.setDropoffLocationModel(dropoffLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _validateAndSubmit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Selection Section
              _buildLocationSection(locationProvider),
              
              const SizedBox(height: 24),
              
              // Trip Type Selection
              _buildTripTypeSelection(),
              
              const SizedBox(height: 24),
              
              // Transport Details Section
              _buildTransportDetailsSection(),
              
              const SizedBox(height: 24),
              
              // Summary and Submit
              _buildSummarySection(locationProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(LocationProvider locationProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Route',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Pickup Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.pickupLocation,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 11.0),
              child: Container(
                width: 2,
                height: 20,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            
            // Dropoff Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dropoff',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.destination,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTripTypeOption(
                    type: TripType.objectTransport,
                    icon: Icons.inventory,
                    title: 'Object Transport',
                    subtitle: 'Documents, packages, furniture...',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTripTypeOption(
                    type: TripType.peopleTransport,
                    icon: Icons.group,
                    title: 'People Transport',
                    subtitle: 'Passenger transportation',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeOption({
    required TripType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedTripType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTripType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.green[50] : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transport Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_selectedTripType == TripType.objectTransport)
              _buildObjectTransportForm()
            else
              _buildPeopleTransportForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectTransportForm() {
    return Column(
      children: [
        // Object Type Dropdown
        DropdownButtonFormField<ObjectType>(
          value: _selectedObjectType,
          decoration: const InputDecoration(
            labelText: 'Object Type',
            border: OutlineInputBorder(),
          ),
          items: ObjectType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getObjectTypeName(type)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedObjectType = value),
          validator: (value) => value == null ? 'Please select object type' : null,
        ),
        
        const SizedBox(height: 16),
        
        // Object Description
        TextFormField(
          controller: _objectDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Object Description',
            hintText: 'Describe the item being transported...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please describe the object';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Weight and Dimensions Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L×W×H cm)',
                  hintText: 'e.g., 30×20×15',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Fragile Checkbox
        CheckboxListTile(
          title: const Text('Fragile Item'),
          value: _isFragile,
          onChanged: (value) => setState(() => _isFragile = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        const SizedBox(height: 16),
        
        // Special Instructions
        TextFormField(
          controller: _specialInstructionsController,
          decoration: const InputDecoration(
            labelText: 'Special Instructions',
            hintText: 'Any special handling requirements...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPeopleTransportForm() {
    return Column(
      children: [
        // Passenger Count
        TextFormField(
          controller: _passengerCountController,
          decoration: const InputDecoration(
            labelText: 'Number of Passengers',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter passenger count';
            }
            final count = int.tryParse(value);
            if (count == null || count <= 0) {
              return 'Please enter valid passenger count';
            }
            return null;
          },
          onChanged: (value) {
            final count = int.tryParse(value) ?? 1;
            setState(() {
              _passengerCount = count;
              _passengerNames = List.generate(count, (index) => '');
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Passenger Names
        if (_passengerNames.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Passenger Names:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(_passengerNames.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Passenger ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _passengerNames[index] = value;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildSummarySection(LocationProvider locationProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (locationProvider.pickupLocationModel != null)
              Text('From: ${locationProvider.pickupLocationModel!.formattedAddress}'),
            
            if (locationProvider.dropoffLocationModel != null)
              Text('To: ${locationProvider.dropoffLocationModel!.formattedAddress}'),
            
            const SizedBox(height: 8),
            
            Text('Trip Type: ${_getTripTypeName(_selectedTripType)}'),
            
            if (_selectedTripType == TripType.objectTransport && _selectedObjectType != null)
              Text('Object: ${_getObjectTypeName(_selectedObjectType!)}'),
            
            if (_selectedTripType == TripType.peopleTransport)
              Text('Passengers: $_passengerCount'),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'CREATE TRIP REQUEST',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);

      // Validate user
      if (userProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Create TransportDetails based on trip type
        TransportDetails transportDetails;
        
        if (_selectedTripType == TripType.objectTransport) {
          transportDetails = TransportDetails(
            objectType: _selectedObjectType,
            objectDescription: _objectDescriptionController.text,
            weight: _weightController.text.isEmpty 
                ? null 
                : double.tryParse(_weightController.text),
            length: _dimensionsController.text.isEmpty 
                ? null 
                : _parseDimension(_dimensionsController.text, 0),
            width: _dimensionsController.text.isEmpty 
                ? null 
                : _parseDimension(_dimensionsController.text, 1),
            height: _dimensionsController.text.isEmpty 
                ? null 
                : _parseDimension(_dimensionsController.text, 2),
            isFragile: _isFragile,
            specialInstructions: _specialInstructionsController.text,
          );
        } else {
          transportDetails = TransportDetails(
            numberOfPassengers: _passengerCount,
            passengerNames: _passengerNames.where((name) => name.isNotEmpty).toList(),
          );
        }

        // Calculate distance and estimated duration
        double distance = locationProvider.distanceValue > 0 
            ? locationProvider.distanceValue / 1000.0 
            : 5.0; // Default 5 km if not calculated
        
        int estimatedDuration = locationProvider.durationValue > 0 
            ? (locationProvider.durationValue / 60).round() 
            : 15; // Default 15 minutes

        // Calculate fare (simple formula: base + per km)
        double fare = 50.0 + (distance * 15.0); // Base 50 + 15 per km

        // Create the trip
        final tripId = await tripsProvider.createTrip(
          userId: userProvider.user!.uid,
          userName: userProvider.user!.name,
          pickupLocation: locationProvider.pickupLocationModel!,
          dropoffLocation: locationProvider.dropoffLocationModel!,
          tripType: _selectedTripType,
          transportDetails: transportDetails,
          distance: distance,
          estimatedDuration: estimatedDuration,
          fare: fare,
        );

        // Close loading dialog
        Navigator.pop(context);

        if (tripId != null) {
          if (widget.isCurrentRide) {
            // For current ride, navigate to searching for driver screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SearchingForDriverScreen()),
            );
          } else {
            // For scheduled ride, show success and go back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip created successfully!')),
            );
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create trip: ${tripsProvider.error}')),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating trip: $e')),
        );
      }
    }
  }

  double? _parseDimension(String dimensions, int index) {
    try {
      final parts = dimensions.split('×');
      if (parts.length > index) {
        return double.tryParse(parts[index].trim());
      }
    } catch (e) {
      return null;
    }
    return null;
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
}