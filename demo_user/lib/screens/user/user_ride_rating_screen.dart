import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRideRatingScreen extends StatefulWidget {
  final String driverId;
  final String tripId;
  final String driverName;
  final double totalFare;

  const UserRideRatingScreen({
    Key? key,
    required this.driverId,
    required this.tripId,
    required this.driverName,
    required this.totalFare,
  }) : super(key: key);

  @override
  State<UserRideRatingScreen> createState() => _UserRideRatingScreenState();
}

class _UserRideRatingScreenState extends State<UserRideRatingScreen> {
  int _selectedRating = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _availableTags = [
    'Cleanliness',
    'Professionalism',
    'Safety',
    'Communication',
    'Value for Money',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Rate your experience';
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Write rating directly to Firestore
      await _firestore.collection('ratings').add({
        'tripId': widget.tripId,
        'driverId': widget.driverId,
        'ratingValue': _selectedRating,
        'tags': _selectedTags.toList(),
        'review': _reviewController.text.trim(),
        'ratedBy': 'user',
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment then go back to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Rate Your Experience'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Driver Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF6A1B9A),
                child: Text(
                  widget.driverName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Driver Name
              Text(
                widget.driverName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Trip Fare: ₹${widget.totalFare.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Star Rating
              const Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () => setState(() => _selectedRating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.star,
                        size: 48,
                        color: index < _selectedRating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _getRatingText(_selectedRating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _selectedRating > 0
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Tags
              if (_selectedRating > 0) ...[
                const Text(
                  'What did you like?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF6A1B9A).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey[300]!,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Review Text
                const Text(
                  'Share your feedback (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What could be improved? Any compliments?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Skip for now'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
