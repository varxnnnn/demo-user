import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/location_provider.dart';
import '../models/trip_model.dart';
import 'map_selection_screen.dart';

class TripCreationScreen extends StatefulWidget {
  static const String id = 'trip_creation_screen';
  
  const TripCreationScreen({Key? key}) : super(key: key);

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
              'Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Pickup Location
            _buildLocationSelector(
              context: context,
              locationProvider: locationProvider,
              isPickup: true,
              location: locationProvider.pickupLocationModel,
              onTap: () => _selectLocation(context, locationProvider, true),
            ),
            
            const SizedBox(height: 16),
            
            const Icon(Icons.arrow_downward, color: Colors.grey),
            
            const SizedBox(height: 16),
            
            // Dropoff Location
            _buildLocationSelector(
              context: context,
              locationProvider: locationProvider,
              isPickup: false,
              location: locationProvider.dropoffLocationModel,
              onTap: () => _selectLocation(context, locationProvider, false),
            ),
            
            const SizedBox(height: 16),
            
            // View on Map Button
            if (locationProvider.pickupLocationModel != null && 
                locationProvider.dropoffLocationModel != null)
              ElevatedButton.icon(
                onPressed: () => _viewRouteOnMap(context, locationProvider),
                icon: const Icon(Icons.map),
                label: const Text('View Route on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required BuildContext context,
    required LocationProvider locationProvider,
    required bool isPickup,
    Location? location,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPickup ? Colors.blue : Colors.green,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: location != null ? Colors.grey[50] : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isPickup ? Icons.my_location : Icons.location_pin,
              color: isPickup ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPickup ? 'Pickup Location' : 'Dropoff Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPickup ? Colors.blue : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location?.formattedAddress ?? 
                        (isPickup ? 'Tap to select pickup' : 'Tap to select destination'),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: location != null ? Colors.grey : 
                    (isPickup ? Colors.blue : Colors.green),
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

  void _selectLocation(BuildContext context, LocationProvider locationProvider, bool isPickup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          isPickup: isPickup,
          initialLocation: isPickup 
              ? locationProvider.pickupLocationModel 
              : locationProvider.dropoffLocationModel,
        ),
      ),
    );
  }

  void _viewRouteOnMap(BuildContext context, LocationProvider locationProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          isPickup: false, // Just to show the route
          initialLocation: locationProvider.pickupLocationModel,
          destinationLocation: locationProvider.dropoffLocationModel,
        ),
      ),
    );
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement trip creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully!')),
      );
      Navigator.pop(context);
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
}