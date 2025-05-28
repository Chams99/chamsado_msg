import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_request_model.dart';

class ChatRequestService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'chat_requests',
  );

  CollectionReference get collection => _collection;

  Future<void> sendRequest(String fromUserId, String toUserId) async {
    await _collection.add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatRequest>> getIncomingRequests(String userId) {
    return _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ChatRequest.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Stream<List<ChatRequest>> getOutgoingRequests(String userId) {
    return _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ChatRequest.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _collection.doc(requestId).update({'status': status});
  }

  Future<bool> isChatAccepted(String userA, String userB) async {
    final query =
        await _collection
            .where('status', isEqualTo: 'accepted')
            .where('fromUserId', whereIn: [userA, userB])
            .where('toUserId', whereIn: [userA, userB])
            .get();
    return query.docs.isNotEmpty;
  }
}
