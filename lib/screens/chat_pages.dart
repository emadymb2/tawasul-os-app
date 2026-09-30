import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, required this.repository, required this.user});

  final ConsoleRepository repository;
  final AuthUser user;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatItem>> _chatsFuture;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    _chatsFuture = _loadChatsAsync();
  }

  Future<List<ChatItem>> _loadChatsAsync() async {
    final rows = await widget.repository.loadChats(widget.user);
    return rows.map((row) => ChatItem.fromJson(row)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: strings.searchChats,
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() => _searchQuery = value),
                )
              : Text(strings.chats),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
              }),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadChats());
          },
          child: FutureBuilder<List<ChatItem>>(
            future: _chatsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final chats = snapshot.data ?? [];
              final filtered = _searchQuery.isEmpty
                  ? chats
                  : chats.where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              if (filtered.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(message: _searchQuery.isEmpty ? strings.noChats : strings.noChats),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  return ChatListTile(
                    chat: chat,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: chat.id,
                        chatName: chat.title,
                        repository: widget.repository,
                        user: widget.user,
                      ),
                    )),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.noChats)),
            );
          },
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  const ChatListTile({super.key, required this.chat, required this.onTap});

  final ChatItem chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        child: chat.avatar.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(chat.avatar), radius: 16)
            : Text(
                chat.title.isEmpty ? '?' : chat.title.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 14),
              ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(chat.title, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (chat.lastMessageDate.isNotEmpty) Text(formatChatTime(chat.lastMessageDate, strings), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
              child: Text('${chat.unreadCount}', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

String formatChatTime(String timestamp, L10n strings) {
  try {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}${diff.inMinutes == 1 ? strings.minute : strings.minutes}';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${date.month}/${date.day}';
  } catch (_) {
    return '';
  }
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId, required this.chatName, required this.repository, required this.user});

  final String chatId;
  final String chatName;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late Future<List<ChatMessageItem>> _messagesFuture;
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    _messagesFuture = widget.repository.loadChatMessages(widget.chatId).then(
      (rows) => rows.map((row) => ChatMessageItem.fromJson(row, currentPersonId: widget.user.personId)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(widget.chatName),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() => _loadMessages()),
                child: FutureBuilder<List<ChatMessageItem>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(message: strings.noMessages),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        return ChatMessageBubble(message: msg, isMine: msg.isMine);
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: strings.typeMessage,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _isSending ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator())
                    : IconButton(
                        icon: const Icon(Icons.send),
                        color: AppColors.pine,
                        onPressed: () => _sendMessage(null),
                      ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String? submittedValue) async {
    final text = submittedValue ?? _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.repository.sendMessage(chatId: widget.chatId, personId: widget.user.personId, content: text);
      _textController.clear();
      setState(() => _loadMessages());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message, required this.isMine});

  final ChatMessageItem message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final alignment = isMine ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bgColor = isMine ? AppColors.pine : AppColors.cream;
    final textColor = isMine ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!isMine && message.senderName.isNotEmpty)
                  Text(message.senderName, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.8))),
                Text(message.content, style: TextStyle(color: textColor)),
                if (message.timestamp.isNotEmpty)
                  Text(formatChatTime(message.timestamp, strings), style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
