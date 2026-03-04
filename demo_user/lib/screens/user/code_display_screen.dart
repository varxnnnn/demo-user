import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CodeDisplayScreen extends StatefulWidget {
  final String tripId;
  const CodeDisplayScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<CodeDisplayScreen> createState() => _CodeDisplayScreenState();
}

class _CodeDisplayScreenState extends State<CodeDisplayScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _sub;
  String? _code;
  DateTime? _expiresAt;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sub = _firestore.collection('trips').doc(widget.tripId).snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final verification = data['verification'];
      if (verification != null) {
        setState(() {
          _code = verification['code']?.toString();
          final ts = verification['expiresAt'] as Timestamp?;
          _expiresAt = ts?.toDate();
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_expiresAt == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        _remaining = _expiresAt!.isAfter(now) ? _expiresAt!.difference(now) : Duration.zero;
      });
      if (_remaining == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Code')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Share this code with the driver to start the trip', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _code ?? '--',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_remaining > Duration.zero ? 'Expires in ${_remaining.inSeconds}s' : 'Expired', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
