
import 'package:booking/data/models/chat_message.dart';
import 'package:booking/data/models/chat_summary.dart';
import 'package:equatable/equatable.dart';
class ChatState extends Equatable {
  final List<ChatSummary> chats;
  final bool chatsLoading;
  final Map<String, List<ChatMessage>> messagesByChat;
  final Map<String, bool> messagesLoading;

  const ChatState({
    this.chats = const [],
    this.chatsLoading = false,
    this.messagesByChat = const {},
    this.messagesLoading = const {},
  });

  ChatState copyWith({
    List<ChatSummary>? chats,
    bool? chatsLoading,
    Map<String, List<ChatMessage>>? messagesByChat,
    Map<String, bool>? messagesLoading,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      chatsLoading: chatsLoading ?? this.chatsLoading,
      messagesByChat: messagesByChat ?? this.messagesByChat,
      messagesLoading: messagesLoading ?? this.messagesLoading,
    );
  }

  @override
  List<Object?> get props => [chats, chatsLoading, messagesByChat, messagesLoading];
}