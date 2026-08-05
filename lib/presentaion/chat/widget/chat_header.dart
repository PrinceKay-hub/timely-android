import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/cubit_presence/presence_cubit.dart';
import 'package:booking/presentaion/chat/widget/chat_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatHeader extends StatelessWidget {
  final String chatId;

  const ChatHeader({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.watch<ChatCubit>();
    final chat = chatCubit.state.chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => throw Exception('Chat not found'),
    );
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const Text('Chat');
    final myUid = authState.user.id;
    final otherUid = chat.participants.firstWhere((id) => id != myUid);
    final otherName = chat.participantNames?[otherUid] ?? 'Chat';
    final otherPhoto = chat.participantPhotos?[otherUid];
    final isProvider = ChatCubit.isProviderInChat(chat, myUid);
    final title = isProvider ? otherName : (chat.serviceName ?? otherName);

    // Subscribe to presence
    context.read<PresenceCubit>().subscribeToPresence(otherUid);
    final presence = context
        .watch<PresenceCubit>()
        .state
        .presenceByUid[otherUid];

    return Row(
      children: [
        ChatAvatar(
          imageUrl: otherPhoto,
          name: otherName,
          size: 36,
          online: presence?.state == 'online',
          ringColor: Colors.white,
          fallbackColor: Colors.white24,
          fallbackTextColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (presence != null)
                Text(
                  formatPresenceLabel(presence),
                  style: TextStyle(
                    fontSize: 12,
                    color: presence.state == 'online'
                        ? Colors.green
                        : Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
