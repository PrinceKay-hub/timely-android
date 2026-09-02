import 'package:booking/data/models/chat_message.dart';
import 'package:booking/data/models/chat_summary.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final List<ChatSummary> chats;
  final bool chatsLoading;
  final Map<String, List<ChatMessage>> messagesByChat;
  final Map<String, bool> messagesLoading;
  // Local-only messages (images currently uploading) not yet confirmed by
  // Firestore. Kept separate from messagesByChat because the messages
  // subscription REPLACES messagesByChat[chatId] wholesale on every
  // snapshot — merging pending messages directly into that map would mean
  // they silently vanish the next time an unrelated snapshot fires before
  // the upload finishes. Reconciled automatically in
  // ChatCubit.subscribeToMessages once the matching doc (same id) shows
  // up in messagesByChat.
  final Map<String, List<ChatMessage>> pendingMessagesByChat;

  const ChatState({
    this.chats = const [],
    this.chatsLoading = false,
    this.messagesByChat = const {},
    this.messagesLoading = const {},
    this.pendingMessagesByChat = const {},
  });

  ChatState copyWith({
    List<ChatSummary>? chats,
    bool? chatsLoading,
    Map<String, List<ChatMessage>>? messagesByChat,
    Map<String, bool>? messagesLoading,
    Map<String, List<ChatMessage>>? pendingMessagesByChat,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      chatsLoading: chatsLoading ?? this.chatsLoading,
      messagesByChat: messagesByChat ?? this.messagesByChat,
      messagesLoading: messagesLoading ?? this.messagesLoading,
      pendingMessagesByChat: pendingMessagesByChat ?? this.pendingMessagesByChat,
    );
  }

  // Server-confirmed messages merged with any still-uploading local
  // images for this chat. Use this everywhere the UI needs "the messages
  // to display" — ChatScreen should read this instead of messagesByChat
  // directly.
  List<ChatMessage> messagesFor(String chatId) {
    final server = messagesByChat[chatId] ?? const [];
    final pending = pendingMessagesByChat[chatId] ?? const [];
    if (pending.isEmpty) return server;
    return [...server, ...pending];
  }

  @override
  List<Object?> get props =>
      [chats, chatsLoading, messagesByChat, messagesLoading, pendingMessagesByChat];
}