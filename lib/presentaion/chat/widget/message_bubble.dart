import 'package:booking/data/models/chat_message.dart';
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/widget/status_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String chatId;

  const MessageBubble({Key? key, required this.message, required this.chatId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final myUid = authState.user.id;
    final isMine = message.senderId == myUid;
    final timeStamp = message.createdAt;

    // Get chat summary
    final chat = context.watch<ChatCubit>().state.chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => throw Exception('Chat not found'),
    );
    final status = ChatCubit.getMessageStatus(message, chat, myUid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMine
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStamp != null
                          ? DateFormat.jm().format(timeStamp)
                          : 'Sending...', // or 'Just now'
                      style: TextStyle(
                        fontSize: 10,
                        color: isMine
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 5),
                    if (isMine) StatusTicks(status: status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}