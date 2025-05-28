import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_settings_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final UserModel friend;

  const ChatPage({Key? key, required this.chatId, required this.friend})
    : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isBlocked = false;
  bool _isBlockedByOther = false;
  List<MessageModel>? _cachedMessages;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
    _preloadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _preloadMessages() async {
    _messageService.getMessages(widget.chatId).first.then((messages) {
      if (mounted) {
        setState(() {
          _cachedMessages = messages;
        });
        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _checkBlockStatus() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      final isBlocked = await _userService.isUserBlocked(
        currentUserId,
        widget.friend.id,
      );
      final isBlockedByOther = await _userService.isUserBlocked(
        widget.friend.id,
        currentUserId,
      );
      setState(() {
        _isBlocked = isBlocked;
        _isBlockedByOther = isBlockedByOther;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _messageService.sendMessage(widget.chatId, currentUserId, text);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                (widget.friend.name?.isNotEmpty == true
                    ? widget.friend.name![0].toUpperCase()
                    : '?'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(widget.friend.name ?? widget.friend.email),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatSettingsPage(
                        chatId: widget.chatId,
                        friendName: widget.friend.name ?? widget.friend.email,
                        friendId: widget.friend.id,
                      ),
                ),
              );
              // Refresh block status when returning from settings
              _checkBlockStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isBlocked || _isBlockedByOther)
            Container(
              color: Colors.red.withOpacity(0.1),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBlocked
                          ? 'You have blocked this user'
                          : 'This user has blocked you',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _preloadMessages,
              child: StreamBuilder<List<MessageModel>>(
                stream: _messageService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? _cachedMessages ?? [];
                  if (messages.isEmpty && !snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color:
                                  isMe
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onBackground,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (!_isBlocked && !_isBlockedByOther)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
