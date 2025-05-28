import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_request_service.dart';
import '../services/message_service.dart';
import '../models/user_model.dart';
import '../models/chat_request_model.dart';
import '../components/custom_app_bar.dart';
import '../components/chat_list_item.dart';
import '../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  final String userEmail;

  HomePage(this.userEmail);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ChatRequestService _chatRequestService = ChatRequestService();
  String _searchQuery = '';
  bool _isLoading = false;
  List<UserModel>? _cachedUsers;
  List<String>? _cachedFriendIds;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      // Preload users data
      _userService.getUsers(currentUserId).first.then((users) {
        if (mounted) {
          setState(() {
            _cachedUsers = users;
          });
        }
      });

      // Preload friend IDs
      _getFriendIds(currentUserId).first.then((friendIds) {
        if (mounted) {
          setState(() {
            _cachedFriendIds = friendIds;
          });
        }
      });
    }
  }

  void _signOut(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update user's online status to offline before signing out
      if (_authService.currentUser != null) {
        try {
          await _userService.updateUserStatus(
            _authService.currentUser!.uid,
            false,
          );
        } catch (e) {
          print('Error updating user status during sign out: $e');
          // Continue with sign out even if status update fails
        }
      }

      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    } catch (e) {
      print('Error during sign out: $e');
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Error signing out. Please try again.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _preloadData();
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // User List
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _getFriendIds(currentUserId),
                builder: (context, friendSnapshot) {
                  final friendIds =
                      friendSnapshot.data ?? _cachedFriendIds ?? [];
                  return StreamBuilder<List<UserModel>>(
                    stream: _userService.getUsers(currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final users = snapshot.data ?? _cachedUsers ?? [];
                      if (users.isEmpty && !snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // Filter users based on search query
                      final filteredUsers =
                          _searchQuery.isEmpty
                              ? users
                              : users.where((user) {
                                final name = user.name?.toLowerCase() ?? '';
                                final email = user.email.toLowerCase();
                                final searchLower = _searchQuery.toLowerCase();
                                return name.contains(searchLower) ||
                                    email.contains(searchLower);
                              }).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context).disabledColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No users found'
                                    : 'No users match your search',
                                style: TextStyle(
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Separate friends and others
                      final friends =
                          filteredUsers
                              .where((user) => friendIds.contains(user.id))
                              .toList();
                      final others =
                          filteredUsers
                              .where((user) => !friendIds.contains(user.id))
                              .toList();

                      return ListView(
                        children: [
                          if (friends.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Friends',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ...friends.map(
                              (user) => ChatListItem(
                                name: user.name ?? user.email,
                                lastMessage:
                                    user.isOnline
                                        ? 'Online'
                                        : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                                time: _formatLastSeen(user.lastSeen),
                                avatarUrl: user.photoUrl,
                                isOnline: user.isOnline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatPage(
                                            chatId: _getChatId(
                                              currentUserId,
                                              user.id,
                                            ),
                                            friend: user,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (others.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Other Users',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ...others.map(
                              (user) => ChatListItem(
                                name: user.name ?? user.email,
                                lastMessage:
                                    user.isOnline
                                        ? 'Online'
                                        : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                                time: _formatLastSeen(user.lastSeen),
                                avatarUrl: user.photoUrl,
                                isOnline: user.isOnline,
                                onTap: () async {
                                  // Only allow sending request, not chat
                                  final outgoingSnapshot =
                                      await _chatRequestService
                                          .getOutgoingRequests(currentUserId)
                                          .first;
                                  final alreadyRequested = outgoingSnapshot.any(
                                    (req) =>
                                        req.toUserId == user.id &&
                                        req.status == 'pending',
                                  );
                                  if (alreadyRequested) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Request already sent and pending.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  final confirmed = await showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text('Send Chat Request?'),
                                          content: Text(
                                            'Do you want to send a chat request to \\${user.name ?? user.email}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Text('Send'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirmed == true) {
                                    await _chatRequestService.sendRequest(
                                      currentUserId,
                                      user.id,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Request sent!'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new chat functionality
        },
        child: Icon(
          Icons.message,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return '\\${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '\\${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '\\${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Change the Future to a Stream for real-time updates
  Stream<List<String>> _getFriendIds(String currentUserId) {
    final firestore = _chatRequestService.collection;

    return firestore
        .where('status', isEqualTo: 'accepted')
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: currentUserId),
            Filter('toUserId', isEqualTo: currentUserId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          final friendIds = <String>{};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final fromUserId = data['fromUserId'] as String;
            final toUserId = data['toUserId'] as String;
            friendIds.add(fromUserId == currentUserId ? toUserId : fromUserId);
          }
          return friendIds.toList();
        });
  }

  void _showPendingRequestsDialog(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Pending Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: StreamBuilder<List<ChatRequest>>(
                      stream: _chatRequestService.getIncomingRequests(
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('No pending requests'),
                            ),
                          );
                        }
                        final requests = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return FutureBuilder<UserModel?>(
                              future: _userService.getUserById(req.fromUserId),
                              builder: (context, userSnap) {
                                final fromUser = userSnap.data;
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      fromUser?.name?.isNotEmpty == true
                                          ? fromUser!.name![0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    fromUser?.name ??
                                        fromUser?.email ??
                                        req.fromUserId,
                                  ),
                                  subtitle: Text('Wants to chat'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () async {
                                          await _chatRequestService
                                              .updateRequestStatus(
                                                req.id,
                                                'accepted',
                                              );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Chat request accepted.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await _chatRequestService
                                              .updateRequestStatus(
                                                req.id,
                                                'rejected',
                                              );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Chat request rejected.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getChatId(String currentUserId, String otherUserId) {
    // Sort the IDs to ensure consistent chat ID generation
    final sortedIds = [currentUserId, otherUserId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}

class UserSearchDelegate extends SearchDelegate {
  final UserService _userService;
  final String _currentUserId;

  UserSearchDelegate(this._userService, this._currentUserId);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getUsers(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        final filteredUsers =
            users.where((user) {
              final name = user.name?.toLowerCase() ?? '';
              final email = user.email.toLowerCase();
              final searchLower = query.toLowerCase();
              return name.contains(searchLower) || email.contains(searchLower);
            }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users found matching "$query"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return ChatListItem(
              name: user.name ?? user.email,
              lastMessage:
                  user.isOnline
                      ? 'Online'
                      : 'Last seen \\${_formatLastSeen(user.lastSeen)}',
              time: _formatLastSeen(user.lastSeen),
              avatarUrl: user.photoUrl,
              isOnline: user.isOnline,
              onTap: () {
                // TODO: Navigate to chat detail page
                close(context, user);
              },
            );
          },
        );
      },
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return '\\${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '\\${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '\\${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
