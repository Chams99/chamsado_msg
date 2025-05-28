import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime timestamp;

  ChatRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.timestamp,
  });

  factory ChatRequest.fromMap(String id, Map<String, dynamic> map) {
    return ChatRequest(
      id: id,
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      status: map['status'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
