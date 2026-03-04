import 'package:flutter/material.dart';
import '../../models/user_ride_request.dart';

class ChatNegotiationScreen extends StatefulWidget {
  final UserRideRequest rideRequest;
  
  const ChatNegotiationScreen({
    super.key,
    required this.rideRequest,
  });

  @override
  State<ChatNegotiationScreen> createState() => _ChatNegotiationScreenState();
}

class _ChatNegotiationScreenState extends State<ChatNegotiationScreen> {
  // ignore: unused_field
  bool _isLoading = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill with current negotiated price or offered price
    _priceController.text = widget.rideRequest.negotiatedPrice?.toStringAsFixed(0) ?? 
                         widget.rideRequest.offeredPrice.toStringAsFixed(0);
    
    // Add initial message about price negotiation
    _messages.add(ChatMessage(
      sender: 'user',
      message: 'I need a ride from ${widget.rideRequest.pickupLocation} to ${widget.rideRequest.dropoffLocation}',
      timestamp: widget.rideRequest.requestedAt,
    ));
    
    _messages.add(ChatMessage(
      sender: 'system',
      message: 'Current offer: ₹${widget.rideRequest.offeredPrice.toStringAsFixed(2)}',
      timestamp: widget.rideRequest.requestedAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Negotiate with ${widget.rideRequest.userName}'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ride Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.rideRequest.pickupLocation} → ${widget.rideRequest.dropoffLocation}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Distance: ${widget.rideRequest.distance.toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'Urgency: ${widget.rideRequest.urgency.toUpperCase()}',
                  style: TextStyle(
                    color: widget.rideRequest.urgency == 'high' ? Colors.red :
                           widget.rideRequest.urgency == 'medium' ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildChatBubble(message);
                },
              ),
            ),
          ),

          // Price Negotiation Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Negotiated Price (₹)',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _sendPriceOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send Offer'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.sender == 'user';
    final isSystem = message.sender == 'system';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Driver avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6A1B9A),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSystem ? Colors.grey[200] :
                       isUser ? const Color(0xFF6A1B9A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser ? const Color(0xFF6A1B9A) : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _sendPriceOffer() async {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Send price negotiation message
      _messages.add(ChatMessage(
        sender: 'driver',
        message: 'I can do this for ₹${price.toStringAsFixed(2)}',
        timestamp: DateTime.now(),
      ));

      // Update the ride request with negotiated price
      // This would normally save to Firestore
      await _updateNegotiatedPrice(price);
      
      _priceController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price offer sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Send message
      _messages.add(ChatMessage(
        sender: 'driver',
        message: _messageController.text,
        timestamp: DateTime.now(),
      ));

      // This would normally save to Firestore/chat service
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNegotiatedPrice(double price) async {
    // This would normally update the ride request in Firestore
    // await FirebaseFirestore.instance
    //     .collection('rideRequests')
    //     .doc(widget.rideRequest.id)
    //     .update({
    //   'negotiatedPrice': price,
    //   'status': 'negotiating',
    //   'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    // });
    
    print('Updating negotiated price to ₹$price for ride ${widget.rideRequest.id}');
  }
}

class ChatMessage {
  final String sender; // 'user', 'driver', 'system'
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
  });
}