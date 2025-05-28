import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Get all users except current user
  Stream<List<UserModel>> getUsers(String currentUserId) {
    return _firestore
        .collection(_collection)
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user online status
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
      // If the document doesn't exist, create it
      if (e is FirebaseException && e.code == 'not-found') {
        await createOrUpdateUser(
          UserModel(
            id: userId,
            email: '', // This will be updated when the user signs in
            lastSeen: DateTime.now(),
            isOnline: isOnline,
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toMap());
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  // Block a user
  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection(_collection).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection(_collection).doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String currentUserId, String otherUserId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data();
        final blockedUsers = List<String>.from(data?['blockedUsers'] ?? []);
        return blockedUsers.contains(otherUserId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }
}
