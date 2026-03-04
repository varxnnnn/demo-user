import 'package:flutter/material.dart';

class SearchingForDriverScreen extends StatefulWidget {
  static const String id = 'searching_for_driver_screen';
  
  const SearchingForDriverScreen({Key? key}) : super(key: key);

  @override
  State<SearchingForDriverScreen> createState() => _SearchingForDriverScreenState();
}

class _SearchingForDriverScreenState extends State<SearchingForDriverScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding Driver'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),
            const Text(
              'Searching for nearby drivers...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              'We\'re connecting you with the nearest available driver',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 4,
            ),
            const SizedBox(height: 30),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 4,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Cancel the search and go back
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}