import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

class ChatSettingsPage extends StatefulWidget {
  final String chatId;
  final String friendName;
  final String friendId;

  const ChatSettingsPage({
    Key? key,
    required this.chatId,
    required this.friendName,
    required this.friendId,
  }) : super(key: key);

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  final UserService _userService = UserService();
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  bool _isBlocked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      final isBlocked = await _userService.isUserBlocked(
        currentUserId,
        widget.friendId,
      );
      setState(() {
        _isBlocked = isBlocked;
      });
    }
  }

  Future<void> _toggleBlockUser() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isBlocked) {
        await _userService.unblockUser(currentUserId, widget.friendId);
      } else {
        await _userService.blockUser(currentUserId, widget.friendId);
      }
      setState(() {
        _isBlocked = !_isBlocked;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear Chat History'),
            content: Text(
              'Are you sure you want to delete all messages in this chat? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _messageService.clearChatHistory(widget.chatId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat history cleared successfully')),
        );
        Navigator.pop(context); // Return to chat page
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Text('Chat Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text('Notifications'),
                subtitle: Text('Manage notification settings'),
                onTap: () {
                  // TODO: Implement notification settings
                },
              ),
              ListTile(
                leading: Icon(
                  _isBlocked ? Icons.block_flipped : Icons.block,
                  color:
                      _isBlocked
                          ? Colors.red
                          : Theme.of(context).colorScheme.secondary,
                ),
                title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
                subtitle: Text(
                  _isBlocked
                      ? 'Unblock \\${widget.friendName}'
                      : 'Block \\${widget.friendName}',
                ),
                onTap: _isLoading ? null : _toggleBlockUser,
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Clear Chat History'),
                subtitle: Text('Delete all messages in this chat'),
                onTap: _isLoading ? null : _clearChatHistory,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
