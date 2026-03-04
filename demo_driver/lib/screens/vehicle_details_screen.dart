import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';
import '../providers/capacity_provider.dart';
import 'home_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String driverId;
  
  const VehicleDetailsScreen({super.key, required this.driverId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _seatsController = TextEditingController();
  final _cargoController = TextEditingController();
  
  String _selectedVehicleType = 'Bike';
  File? _vehicleImage;
  File? _rcBookImage;
  bool _isLoading = false;
  
  final List<String> _vehicleTypes = ['Bike', 'Auto', 'Car'];
  final ImagePicker _picker = ImagePicker();

  String _generateStoragePath(String folder) {
    final uuid = _generateUUID();
    if (folder == 'vehicle_images') {
      return 'vehicle/$uuid';
    } else if (folder == 'rc_books') {
      return 'rc_book/$uuid';
    } else {
      return '$folder/$uuid';
    }
  }
  
  String _generateUUID() {
    // Simple UUID generation
    var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var uuid = '';
    for (int i = 0; i < 8; i++) {
      uuid += chars[(DateTime.now().microsecondsSinceEpoch + i) % chars.length];
    }
    uuid += '-';
    for (int i = 0; i < 4; i++) {
      uuid += chars[(DateTime.now().microsecondsSinceEpoch + i + 10) ~/ 10 % chars.length];
    }
    uuid += '-';
    for (int i = 0; i < 4; i++) {
      uuid += chars[(DateTime.now().microsecondsSinceEpoch + i + 100) ~/ 100 % chars.length];
    }
    uuid += '-';
    for (int i = 0; i < 4; i++) {
      uuid += chars[(DateTime.now().microsecondsSinceEpoch + i + 1000) ~/ 1000 % chars.length];
    }
    uuid += '-';
    for (int i = 0; i < 12; i++) {
      uuid += chars[(DateTime.now().microsecondsSinceEpoch + i + 10000) ~/ 10000 % chars.length];
    }
    return uuid;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _seatsController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isVehicle) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isVehicle) {
            _vehicleImage = File(pickedFile.path);
          } else {
            _rcBookImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ' + e.toString())),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile, String folder) async {
    try {
      // Wait a moment to ensure authentication is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      String storagePath = _generateStoragePath(folder);
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Image uploaded successfully to path: \$storagePath');
        print('Download URL: \$downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: \${snapshot.state}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error uploading image: ' + e.toString());
      print('Stack trace: ' + stackTrace.toString());
      // Provide more specific error feedback
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') ||
          errorMessage.contains('403') ||
          errorMessage.contains('denied')) {
        throw Exception('Storage permission error. Please ensure you are logged in and try again.');
      } else if (errorMessage.contains('network') ||
                 errorMessage.contains('connection') ||
                 errorMessage.contains('timeout')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Upload failed: \$e');
      }
    }
  }

  Future<void> _submitVehicleDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_vehicleImage == null || _rcBookImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both vehicle and RC book images'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Upload images
        String? vehicleImageUrl;
        String? rcBookImageUrl;
        
        if (_vehicleImage != null) {
          vehicleImageUrl = await _uploadImage(_vehicleImage!, 'vehicle_images');
        }
        if (_rcBookImage != null) {
          rcBookImageUrl = await _uploadImage(_rcBookImage!, 'rc_books');
        }

        if (vehicleImageUrl == null || rcBookImageUrl == null) {
          throw Exception('Failed to upload images. Please check your internet connection and try again.');
        }

        // Create vehicle object
        Vehicle vehicle = Vehicle(
          id: '${widget.driverId}_${DateTime.now().millisecondsSinceEpoch}',
          driverId: widget.driverId,
          vehicleType: _selectedVehicleType,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          registrationNumber: _registrationController.text.trim(),
          rcBookUrl: rcBookImageUrl,
          vehicleImageUrl: vehicleImageUrl,
          isVerified: false,
          createdAt: DateTime.now(),
        );

        // Save to database
        final vehicleService = Provider.of<VehicleService>(context, listen: false);
        await vehicleService.addVehicle(vehicle);

        // Save vehicle capacity
        final capacityProvider = Provider.of<CapacityProvider>(context, listen: false);
        await capacityProvider.initializeDriverCapacity(
          widget.driverId,
          int.parse(_seatsController.text),
          int.parse(_cargoController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ' + e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String? _getPlaceholderImage() {
    return 'assets/img.jpg';
  }
  
  void _showImagePickerDialog(bool isVehicle) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isVehicle);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isVehicle);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bike,
                    size: 50,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Vehicle Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Add your vehicle information',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Form Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF311B92),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Vehicle Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleType,
                          decoration: InputDecoration(
                            labelText: 'Vehicle Type',
                            prefixIcon: const Icon(Icons.local_shipping_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          items: _vehicleTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedVehicleType = newValue;
                              });
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Brand Field
                        TextFormField(
                          controller: _brandController,
                          decoration: InputDecoration(
                            labelText: 'Brand',
                            hintText: 'e.g., Honda, TVS, Bajaj',
                            prefixIcon: const Icon(Icons.branding_watermark_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vehicle brand';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Model Field
                        TextFormField(
                          controller: _modelController,
                          decoration: InputDecoration(
                            labelText: 'Model',
                            hintText: 'e.g., Activa, Ntorq, Pulsar',
                            prefixIcon: const Icon(Icons.model_training_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vehicle model';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Registration Number Field
                        TextFormField(
                          controller: _registrationController,
                          decoration: InputDecoration(
                            labelText: 'Registration Number',
                            hintText: 'e.g., KA01AB1234',
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter registration number';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Seats Field
                        TextFormField(
                          controller: _seatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total Seats',
                            hintText: 'e.g., 4',
                            prefixIcon: const Icon(Icons.event_seat),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of seats';
                            }
                            final seats = int.tryParse(value);
                            if (seats == null || seats <= 0) {
                              return 'Please enter a valid number of seats';
                            }
                            if (seats > 20) {
                              return 'Seats should be 20 or less';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Cargo Capacity Field
                        TextFormField(
                          controller: _cargoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Cargo Capacity (kg)',
                            hintText: 'e.g., 10',
                            prefixIcon: const Icon(Icons.local_shipping),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A1B9A),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter cargo capacity';
                            }
                            final cargo = double.tryParse(value);
                            if (cargo == null || cargo <= 0) {
                              return 'Please enter a valid cargo capacity';
                            }
                            if (cargo > 1000) {
                              return 'Cargo capacity should be 1000 kg or less';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Upload Documents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF311B92),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Vehicle Image Upload
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vehicle Image',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showImagePickerDialog(true),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _vehicleImage == null 
                                          ? const Color(0xFF6A1B9A) 
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: _vehicleImage == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _vehicleImage == null && _getPlaceholderImage() != null
                                                ? Image.asset(
                                                    _getPlaceholderImage()!,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.contain,
                                                  )
                                                : const Icon(
                                                    Icons.add_a_photo,
                                                    size: 40,
                                                    color: Color(0xFF6A1B9A),
                                                  ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Tap to upload vehicle photo',
                                              style: TextStyle(color: Color(0xFF6A1B9A)),
                                            ),
                                          ],
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.file(
                                            _vehicleImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // RC Book Image Upload
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RC Book Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showImagePickerDialog(false),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _rcBookImage == null 
                                          ? const Color(0xFF6A1B9A) 
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: _rcBookImage == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _rcBookImage == null && _getPlaceholderImage() != null
                                                ? Image.asset(
                                                    _getPlaceholderImage()!,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.contain,
                                                  )
                                                : const Icon(
                                                    Icons.upload_file,
                                                    size: 40,
                                                    color: Color(0xFF6A1B9A),
                                                  ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Tap to upload RC book photo',
                                              style: TextStyle(color: Color(0xFF6A1B9A)),
                                            ),
                                          ],
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.file(
                                            _rcBookImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitVehicleDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text(
                                    'SUBMIT DETAILS',
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
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}