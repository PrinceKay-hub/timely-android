import 'package:booking/data/models/chat_summary.dart';
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_state.dart';
import 'package:booking/presentaion/chat/cubit_presence/presence_cubit.dart';
import 'package:booking/presentaion/chat/widget/chat_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatsList extends StatefulWidget {
  const ChatsList({Key? key}) : super(key: key);

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  late ChatCubit _chatCubit; 
  late AuthCubit _authCubit; 


  @override
  void initState() {
    super.initState();

    _chatCubit = context.read<ChatCubit>();
    _authCubit = context.read<AuthCubit>();
    // Assume we have auth user id
    final authState = _authCubit.state;
    if (authState is AuthAuthenticated) {
      _chatCubit.subscribeToChats(authState.user.id);
    }
  }

  @override
  void dispose() {
    _chatCubit.unsubscribeChats();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
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
            title: Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state.chatsLoading && state.chats.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.chats.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('💬', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 12),
                    Text('No conversations yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Messages with your bookings will show up here'),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.chats.length,
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return _ChatRow(chat: chat);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final ChatSummary chat;

  const _ChatRow({Key? key, required this.chat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final myUid = authState.user.id;
    final otherUid = chat.participants.firstWhere((id) => id != myUid);
    final otherName = chat.participantNames?[otherUid] ?? chat.serviceName ?? 'Chat';
    final otherPhoto = chat.participantPhotos?[otherUid];
    final unread = chat.unreadCount[myUid] ?? 0;
    final isProvider = ChatCubit.isProviderInChat(chat, myUid);
    final title = isProvider ? otherName : (chat.serviceName ?? otherName);

    // Subscribe to presence
    context.read<PresenceCubit>().subscribeToPresence(otherUid);
    final presence = context.watch<PresenceCubit>().state.presenceByUid[otherUid];
    final online = presence?.state == 'online';

    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: ChatAvatar(
        imageUrl: otherPhoto,
        name: otherName,
        size: 52,
        online: online,
        ringColor: Theme.of(context).scaffoldBackgroundColor,
        fallbackColor: colorScheme.primary.withOpacity(0.2),
        fallbackTextColor: colorScheme.primary,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          // Show status tick only if the last message is from the current user
          if (chat.lastSenderId == myUid) ...[
            _buildStatusTick(chat, myUid),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              chat.lastMessage ?? 'Say hello 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                color: unread > 0 ? colorScheme.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chat.lastMessageAt != null
                ? DateFormat.jm().format(chat.lastMessageAt!)
                : '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      onTap: () {
        context.push('/chat/${chat.id}');
      },
    );
  }

  // Helper to determine message status and return the appropriate icon
  Widget _buildStatusTick(ChatSummary chat, String myUid) {
    // Get the other participant
    final otherUid = chat.participants.firstWhere((id) => id != myUid);

    // Timestamp of the last message (in milliseconds)
    final int? msgMs = chat.lastMessageAt?.millisecondsSinceEpoch;
    if (msgMs == null) return const SizedBox.shrink();

    // Read/delivered timestamps for the other user
    final int? readMs = chat.readTo?[otherUid]?.millisecondsSinceEpoch;
    final int? deliveredMs = chat.deliveredTo?[otherUid]?.millisecondsSinceEpoch;

    IconData iconData;
    Color color;

    if (readMs != null && readMs >= msgMs) {
      // Seen (double check, blue)
      iconData = Icons.done_all;
      color = Colors.blue;
    } else if (deliveredMs != null && deliveredMs >= msgMs) {
      // Delivered (double check, grey)
      iconData = Icons.done_all;
      color = Colors.grey;
    } else {
      // Sent (single check, grey)
      iconData = Icons.done;
      color = Colors.grey;
    }

    return Icon(iconData, size: 14, color: color);
  }
}