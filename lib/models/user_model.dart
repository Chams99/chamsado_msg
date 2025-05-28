import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool isOnline;
  final DateTime lastSeen;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.isOnline = false,
    required this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen:
          map['lastSeen'] != null
              ? (map['lastSeen'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }
}
