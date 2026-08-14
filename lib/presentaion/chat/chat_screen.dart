import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_state.dart';
import 'package:booking/presentaion/chat/widget/chat_dot_bg.dart';
import 'package:booking/presentaion/chat/widget/chat_header.dart';
import 'package:booking/presentaion/chat/widget/date_header.dart';
import 'package:booking/presentaion/chat/widget/message_bubble.dart';
import 'package:booking/presentaion/chat/widget/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastMarkedReadAt;
  late ChatCubit _chatCubit;
  late AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _chatCubit = context.read<ChatCubit>();
    _authCubit = context.read<AuthCubit>();

    _chatCubit.subscribeToMessages(widget.chatId);

    final authState = _authCubit.state;
    if (authState is AuthAuthenticated) {
      _chatCubit.markChatRead(widget.chatId, authState.user.id);

      final chat = _chatCubit.state.chats.firstWhere(
        (c) => c.id == widget.chatId,
        orElse: () => throw Exception('Chat not found'),
      );
      _lastMarkedReadAt = chat.readTo?[authState.user.id] ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _chatCubit.unsubscribeMessages(
      widget.chatId,
    ); 
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final authState = _authCubit.state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in')));
      return;
    }

    _textController.clear();
    try {
      await _chatCubit.sendMessage(widget.chatId, authState.user.id, text);
    } catch (e, stack) {
      print('Send error: $e\n$stack');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      _textController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          title: ChatHeader(chatId: widget.chatId),
        ),
        body: ChatDotBackground(
          child: BlocListener<ChatCubit, ChatState>(
            listener: (context, state) {
              final messages = state.messagesByChat[widget.chatId];
              if (messages == null || messages.isEmpty) return;
      
              final lastMsg = messages.last;
              final authState = context.read<AuthCubit>().state;
              if (authState is! AuthAuthenticated) return;
      
              // Only react to messages from the other user
              if (lastMsg.senderId == authState.user.id) return;
      
              final msgTime = lastMsg.createdAt;
              if (msgTime == null) return;
      
              // If this message is newer than the last one we marked read, mark read
              if (_lastMarkedReadAt == null ||
                  msgTime.isAfter(_lastMarkedReadAt!)) {
                context.read<ChatCubit>().markChatRead(
                  widget.chatId,
                  authState.user.id,
                );
                _lastMarkedReadAt = msgTime;
              }
            },
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                final messages = state.messagesByChat[widget.chatId] ?? [];
                final loading = state.messagesLoading[widget.chatId] ?? false;
                if (loading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Reverse for display (newest at bottom)
                final groupedItems = _buildGroupedMessages(messages);
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: groupedItems.length,
                        itemBuilder: (context, index) {
                          // Because reverse is true, we need to access items from the end
                          final item =
                              groupedItems[groupedItems.length - 1 - index];
                          if (item is DateTime) {
                            return DateHeader(date: item);
                          } else {
                            return MessageBubble(
                              message: item as ChatMessage,
                              chatId: widget.chatId,
                            );
                          }
                        },
                      ),
                    ),
                    SafeArea(
                      child: MessageInput(
                        controller: _textController,
                        onSend: () {
                          _sendMessage();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _buildGroupedMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];

    // Sort chronologically (oldest first)
    final sorted = List<ChatMessage>.from(messages)
      ..sort(
        (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
          b.createdAt ?? DateTime.now(),
        ),
      );

    final Map<DateTime, List<ChatMessage>> groups = {};
    for (final msg in sorted) {
      final date = DateTime(
        (msg.createdAt ?? DateTime.now()).year,
        (msg.createdAt ?? DateTime.now()).month,
        (msg.createdAt ?? DateTime.now()).day,
      );
      groups.putIfAbsent(date, () => []).add(msg);
    }

    final List<dynamic> items = [];
    final keys = groups.keys.toList()..sort();
    for (final key in keys) {
      items.add(key); // header
      items.addAll(groups[key]!);
    }
    return items;
  }
}
