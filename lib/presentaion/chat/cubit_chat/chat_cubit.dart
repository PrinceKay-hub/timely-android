import 'dart:async';
import 'package:booking/core/services/send_notification.dart';
import 'package:booking/data/models/chat_summary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/chat_message.dart';
import 'chat_state.dart';

// Helper to generate deterministic chat ID
String chatIdFor(String uidA, String uidB) {
  final List<String> sorted = [uidA, uidB]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

// In-memory dedup cache for delivered marks
final Set<String> _deliveredMarkCache = {};

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(const ChatState());

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _messagesSubscriptions = {};

  // Firestore instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Chat list subscription ──────────────────────────
  void subscribeToChats(String uid) {
    if (_chatsSubscription != null) return;
    emit(state.copyWith(chatsLoading: true));

    final query = _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true);

    _chatsSubscription = query.snapshots().listen((snapshot) {
      final chats = snapshot.docs.map((doc) => ChatSummary.fromFirestore(doc)).toList();
      emit(state.copyWith(chats: chats, chatsLoading: false));

      // "Delivered" piggyback: mark delivered for messages from others
      for (final chat in chats) {
        if (chat.lastSenderId == null || chat.lastSenderId == uid || chat.lastMessageAt == null) continue;
        final lastMsgMs = chat.lastMessageAt!.millisecondsSinceEpoch;
        final cacheKey = '${chat.id}:$lastMsgMs';
        if (_deliveredMarkCache.contains(cacheKey)) continue;
        _deliveredMarkCache.add(cacheKey);

        _firestore
            .collection('chats')
            .doc(chat.id)
            .update({'deliveredTo.$uid': FieldValue.serverTimestamp()})
            .catchError((e) => print('Failed to mark delivered: $e'));
      }
    }, onError: (error) {
      print('Chats subscription error: $error');
      emit(state.copyWith(chatsLoading: false));
    });
  }

  // ─── Messages subscription ──────────────────────────
  void subscribeToMessages(String chatId) {
    // If already subscribed, do nothing
    if (_messagesSubscriptions.containsKey(chatId)) return;

    emit(state.copyWith(
      messagesLoading: {...state.messagesLoading, chatId: true},
    ));

    final query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    final sub = query.snapshots(includeMetadataChanges: true).listen((snapshot) {
      final messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
      final updatedMessagesByChat = Map<String, List<ChatMessage>>.from(state.messagesByChat);
      updatedMessagesByChat[chatId] = messages;
      final updatedLoading = Map<String, bool>.from(state.messagesLoading);
      updatedLoading[chatId] = false;
      emit(state.copyWith(
        messagesByChat: updatedMessagesByChat,
        messagesLoading: updatedLoading,
      ));
    }, onError: (error) {
      print('Messages subscription error: $error');
      final updatedLoading = Map<String, bool>.from(state.messagesLoading);
      updatedLoading[chatId] = false;
      emit(state.copyWith(messagesLoading: updatedLoading));
    });

    _messagesSubscriptions[chatId] = sub;
  }

  // ─── Unsubscribe ─────────────────────────────────────
  void unsubscribeChats() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
  }

  void unsubscribeMessages(String chatId) {
    _messagesSubscriptions[chatId]?.cancel();
    _messagesSubscriptions.remove(chatId);
  }

  void disposeAll() {
    unsubscribeChats();
    for (final sub in _messagesSubscriptions.values) {
      sub.cancel();
    }
    _messagesSubscriptions.clear();
  }

  // ─── Get or Create Chat ─────────────────────────────
  Future<String> getOrCreateChat({
    required String currentUserId,
    String? currentUserName,
    String? currentUserPhoto,
    required String otherUserId,
    String? otherUserName,
    String? otherUserPhoto,
    String? serviceId,
    String? serviceName,
    String? providerId,
  }) async {
    final chatId = chatIdFor(currentUserId, otherUserId);
    final docRef = _firestore.collection('chats').doc(chatId);
    final docSnap = await docRef.get();

    final resolvedProviderId = providerId ?? otherUserId;

    if (!docSnap.exists) {
      final newChat = {
        'participants': [currentUserId, otherUserId]..sort(),
        'participantNames': {
          if (currentUserName != null) currentUserId: currentUserName,
          if (otherUserName != null) otherUserId: otherUserName,
        },
        'participantPhotos': {
          if (currentUserPhoto != null) currentUserId: currentUserPhoto,
          if (otherUserPhoto != null) otherUserId: otherUserPhoto,
        },
        'serviceId': serviceId,
        'serviceName': serviceName,
        'providerId': resolvedProviderId,
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(newChat);
    } else {
      // Update metadata if needed
      final existing = ChatSummary.fromFirestore(docSnap);
      final updates = <String, dynamic>{};
      if (currentUserName != null &&
          (existing.participantNames?[currentUserId] != currentUserName)) {
        updates['participantNames.$currentUserId'] = currentUserName;
      }
      if (otherUserName != null &&
          (existing.participantNames?[otherUserId] != otherUserName)) {
        updates['participantNames.$otherUserId'] = otherUserName;
      }
      if (currentUserPhoto != null &&
          (existing.participantPhotos?[currentUserId] != currentUserPhoto)) {
        updates['participantPhotos.$currentUserId'] = currentUserPhoto;
      }
      if (otherUserPhoto != null &&
          (existing.participantPhotos?[otherUserId] != otherUserPhoto)) {
        updates['participantPhotos.$otherUserId'] = otherUserPhoto;
      }
      if (existing.providerId == null) {
        updates['providerId'] = resolvedProviderId;
      }
      if (updates.isNotEmpty) {
        await docRef.update(updates);
      }
    }
    return chatId;
  }

  // ─── Send Message ────────────────────────────────────
  // ─── Send Message ────────────────────────────────────
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnap = await chatRef.get();
      if (!chatSnap.exists) throw Exception('Chat does not exist');

      final chat = ChatSummary.fromFirestore(chatSnap);
      final otherUid = chat.participants.firstWhere((id) => id != senderId);
      if (otherUid.isEmpty) throw Exception('Could not determine recipient');

      // Add message
      final messagesRef = chatRef.collection('messages');
      await messagesRef.add({
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ─── Send push notification to receiver ──────────
      final senderName = chat.participantNames?[senderId] ?? 'User';
      await _sendPushNotification(
        receiverId: otherUid,
        senderName: senderName,
        messageText: text,
        chatId: chatId
      );

      // Update chat metadata
      await chatRef.update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount.$otherUid': FieldValue.increment(1),
      });

    } catch (e) {
      print('sendMessage error: $e');
      rethrow;
    }
  }

  // ─── Mark Read ───────────────────────────────────────
  Future<void> markChatRead(String chatId, String uid) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.update({
        'unreadCount.$uid': 0,
        'readTo.$uid': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to mark chat read: $e');
    }
  }

  // ─── Selectors (compute total unread) ──────────────
  int getTotalUnread(String uid) {
    return state.chats.fold<int>(
        0, (sum, chat) => sum + (chat.unreadCount[uid] ?? 0));
  }

  // Utility to check if a user is the provider in a chat
  static bool isProviderInChat(ChatSummary? chat, String? uid) {
    return chat?.providerId != null && chat?.providerId == uid;
  }

  // Utility to get message status (sending, sent, delivered, seen)
  static MessageStatus getMessageStatus(
    ChatMessage message,
    ChatSummary? chat,
    String myUid,
  ) {
    if (message.pending) return MessageStatus.sending;
    if (chat == null) return MessageStatus.sent;

    final otherUid = chat.participants.firstWhere((id) => id != myUid);
    final msgMs = message.createdAt?.millisecondsSinceEpoch;
    if (msgMs == null) return MessageStatus.sent;

    final readMs = chat.readTo?[otherUid]?.millisecondsSinceEpoch;
    if (readMs != null && readMs >= msgMs) return MessageStatus.seen;

    final deliveredMs = chat.deliveredTo?[otherUid]?.millisecondsSinceEpoch;
    if (deliveredMs != null && deliveredMs >= msgMs) return MessageStatus.delivered;

    return MessageStatus.sent;
  }

  // ─── Private push helper ─────────────────────────────
  Future<void> _sendPushNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    try {
      // Fetch receiver's FCM token
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!userDoc.exists) return;
      final token = userDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      final body = messageText;

      await SendNotificationService().sendNotificationViaCloudFunction(
        title: senderName,
        body: body,
        deviceToken: token,
        data: {
        'type': 'chat',
        'chatId': chatId,
      },
      );
    } catch (e) {
      // Log but do not rethrow – we don't want to fail the message sending
      print('Push notification error: $e');
    }
  }
}

enum MessageStatus { sending, sent, delivered, seen }