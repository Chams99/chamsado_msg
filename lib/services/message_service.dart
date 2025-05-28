import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'user_service.dart';

class MessageService {
  final _collection = FirebaseFirestore.instance.collection('messages');
  final _userService = UserService();

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _collection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => MessageModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    // Extract the other user's ID from the chatId
    final userIds = chatId.split('_');
    final otherUserId = userIds.firstWhere((id) => id != senderId);

    // Check if either user has blocked the other
    final isBlockedByMe = await _userService.isUserBlocked(
      senderId,
      otherUserId,
    );
    final isBlockedByOther = await _userService.isUserBlocked(
      otherUserId,
      senderId,
    );

    if (isBlockedByMe || isBlockedByOther) {
      throw Exception('Cannot send message: User is blocked');
    }

    await _collection.add({
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now(),
    });
  }

  // Helper to generate a unique chatId for two users
  static String getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return sorted.join('_');
  }

  // Clear chat history
  Future<void> clearChatHistory(String chatId) async {
    try {
      final messages =
          await _collection.where('chatId', isEqualTo: chatId).get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing chat history: $e');
      rethrow;
    }
  }
}
