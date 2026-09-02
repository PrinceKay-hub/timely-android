import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:booking/core/services/send_notification.dart';
import 'package:booking/data/models/chat_summary.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final Map<String, StreamSubscription<QuerySnapshot>> _messagesSubscriptions =
      {};

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

    _chatsSubscription = query.snapshots().listen(
      (snapshot) {
        final chats = snapshot.docs
            .map((doc) => ChatSummary.fromFirestore(doc))
            .toList();
        emit(state.copyWith(chats: chats, chatsLoading: false));

        // "Delivered" piggyback: mark delivered for messages from others
        for (final chat in chats) {
          if (chat.lastSenderId == null ||
              chat.lastSenderId == uid ||
              chat.lastMessageAt == null)
            continue;
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
      },
      onError: (error) {
        print('Chats subscription error: $error');
        emit(state.copyWith(chatsLoading: false));
      },
    );
  }

  // ─── Messages subscription ──────────────────────────
  void subscribeToMessages(String chatId) {
    // If already subscribed, do nothing
    if (_messagesSubscriptions.containsKey(chatId)) return;

    emit(
      state.copyWith(messagesLoading: {...state.messagesLoading, chatId: true}),
    );

    final query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    final sub = query
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            final updatedMessagesByChat = Map<String, List<ChatMessage>>.from(
              state.messagesByChat,
            );
            updatedMessagesByChat[chatId] = messages;
            final updatedLoading = Map<String, bool>.from(
              state.messagesLoading,
            );
            updatedLoading[chatId] = false;

            // Reconcile pending (uploading) image messages: once a message with
            // the same id shows up here, it's confirmed by Firestore — drop the
            // local optimistic copy so we don't render both.
            Map<String, List<ChatMessage>>? updatedPending;
            final currentPending = state.pendingMessagesByChat[chatId];
            if (currentPending != null && currentPending.isNotEmpty) {
              final confirmedIds = messages.map((m) => m.id).toSet();
              final remaining = currentPending
                  .where((m) => !confirmedIds.contains(m.id))
                  .toList();
              if (remaining.length != currentPending.length) {
                updatedPending = Map<String, List<ChatMessage>>.from(
                  state.pendingMessagesByChat,
                );
                updatedPending[chatId] = remaining;
              }
            }

            emit(
              state.copyWith(
                messagesByChat: updatedMessagesByChat,
                messagesLoading: updatedLoading,
                pendingMessagesByChat: updatedPending,
              ),
            );
          },
          onError: (error) {
            print('Messages subscription error: $error');
            final updatedLoading = Map<String, bool>.from(
              state.messagesLoading,
            );
            updatedLoading[chatId] = false;
            emit(state.copyWith(messagesLoading: updatedLoading));
          },
        );

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
    ChatSummary chatSummary;

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

      final now = DateTime.now();
      chatSummary = ChatSummary(
        id: chatId,
        participants: [currentUserId, otherUserId]..sort(),
        participantNames: {
          if (currentUserName != null) currentUserId: currentUserName,
          if (otherUserName != null) otherUserId: otherUserName,
        },
        participantPhotos: {
          if (currentUserPhoto != null) currentUserId: currentUserPhoto,
          if (otherUserPhoto != null) otherUserId: otherUserPhoto,
        },
        serviceId: serviceId,
        serviceName: serviceName,
        providerId: resolvedProviderId,
        unreadCount: {currentUserId: 0, otherUserId: 0},
        lastMessage: '',
        lastMessageAt: now,
        createdAt: now,
      );
    } else {
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
      chatSummary = existing;
    }

    final exists = state.chats.any((c) => c.id == chatId);
    if (!exists) {
      emit(state.copyWith(chats: [chatSummary, ...state.chats]));
    }

    return chatId;
  }

  Map<String, dynamic> _replyFields(ChatMessage? replyTo, ChatSummary chat) {
  if (replyTo == null) return {};
  final senderName = chat.participantNames?[replyTo.senderId] ?? 'User';
  final isImage = replyTo.type == MessageType.image;
  return {
    'replyToId': replyTo.id,
    'replyToSenderId': replyTo.senderId,
    'replyToSenderName': senderName,
    'replyToType': isImage ? 'image' : 'text',
    'replyToText': isImage ? null : replyTo.text,
    if (isImage) 'replyToImageUrl': replyTo.imageUrl,
  };
}

  // ─── Send Message (text) ─────────────────────────────
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    ChatMessage? replyTo,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnap = await chatRef.get();
      if (!chatSnap.exists) throw Exception('Chat does not exist');

      final chat = ChatSummary.fromFirestore(chatSnap);
      final otherUid = chat.participants.firstWhere((id) => id != senderId);
      if (otherUid.isEmpty) throw Exception('Could not determine recipient');

      final messagesRef = chatRef.collection('messages');
      await messagesRef.add({
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        ..._replyFields(replyTo, chat),
      });

      final senderName = chat.participantNames?[senderId] ?? 'User';
      await _sendPushNotification(
        receiverId: otherUid,
        senderName: senderName,
        messageText: text,
        chatId: chatId,
      );

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

  // "Delete for me" — hides it locally for this user only. Cheap, no
  // fan-out concerns, doesn't affect the other participant's view.
  Future<void> deleteMessageForMe(
    String chatId,
    String messageId,
    String uid,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([uid]),
          });
    } catch (e) {
      print('deleteMessageForMe error: $e');
    }
  }

  // "Delete for everyone" — soft delete. Wipes content but keeps the doc
  // as a tombstone (so ordering/pagination and lastMessage don't break if
  // it was the newest message). Also patches chat.lastMessage if this
  // was the most recent one, matching WhatsApp's "This message was deleted".
  Future<void> deleteMessageForEveryone(String chatId, String messageId, String senderId) async {
  try {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc(messageId);

    // Read first so we know whether there's an image to clean up —
    // the update below wipes imageUrl, so we'd lose the reference
    // after that point.
    final msgSnap = await msgRef.get();
    final hadImage = (msgSnap.data()?['type'] == 'image');

    await msgRef.update({'isDeleted': true, 'text': '', 'imageUrl': null});

    if (hadImage) {
      try {
        await FirebaseStorage.instance
            .ref()
            .child('chats')
            .child(chatId)
            .child('$messageId.jpg')
            .delete();
      } catch (e) {
        // Object may already be gone (e.g. retried send under a
        // different messageId) — not fatal to the delete operation.
        print('Storage cleanup failed: $e');
      }
    }

    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) return;
    final chat = ChatSummary.fromFirestore(chatSnap);
    if (chat.lastSenderId == senderId) {
      final latestSnap = await chatRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (latestSnap.docs.isNotEmpty && latestSnap.docs.first.id == messageId) {
        await chatRef.update({'lastMessage': 'This message was deleted'});
      }
    }
  } catch (e) {
    print('deleteMessageForEveryone error: $e');
  }
}

  // ─── Send Message (image) ────────────────────────────
  // Optimistic: an image message appears immediately, rendered straight
  // from the local file, with an upload-progress ring on top. The
  // Firestore doc ID is pre-allocated (via .doc() with no args, which is
  // free — no network round-trip) and reused as both the optimistic
  // message's id AND the id it's eventually written under. That's what
  // lets subscribeToMessages' snapshot listener naturally supersede the
  // local preview once the real doc lands, instead of showing a
  // duplicate bubble.
  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    File imageFile, {
    ChatMessage? replyTo,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    final messageId = messageRef.id;
    final localCreatedAt = DateTime.now();

    Size? dimensions;
    try {
      dimensions = await _readImageDimensions(imageFile);
    } catch (e) {
      print('Failed to read image dimensions: $e');
    }

    final optimisticMessage = ChatMessage(
      id: messageId,
      senderId: senderId,
      text: '',
      createdAt: localCreatedAt,
      pending: true,
      type: MessageType.image,
      imageWidth: dimensions?.width,
      imageHeight: dimensions?.height,
      localImagePath: imageFile.path,
      uploadProgress: 0.0,
      replyToId: replyTo?.id,
      replyToSenderId: replyTo?.senderId,
      replyToType: replyTo?.type,
      replyToText: replyTo?.type == MessageType.image ? null : replyTo?.text,
      replyToImageUrl: replyTo?.type == MessageType.image
          ? replyTo?.imageUrl
          : null,
    );

    _addPendingMessage(chatId, optimisticMessage);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chats')
          .child(chatId)
          .child('$messageId.jpg');

      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes <= 0) return;
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _updatePendingMessage(
          chatId,
          messageId,
          (m) => m.copyWith(uploadProgress: progress),
        );
      });

      final completedSnapshot = await uploadTask;
      final imageUrl = await completedSnapshot.ref.getDownloadURL();

      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnap = await chatRef.get();
      if (!chatSnap.exists) throw Exception('Chat does not exist');
      final chat = ChatSummary.fromFirestore(chatSnap);
      final otherUid = chat.participants.firstWhere((id) => id != senderId);

      await messageRef.set({
        'senderId': senderId,
        'text': '',
        'type': 'image',
        'imageUrl': imageUrl,
        if (dimensions != null) 'imageWidth': dimensions.width,
        if (dimensions != null) 'imageHeight': dimensions.height,
        'createdAt': FieldValue.serverTimestamp(),
        ..._replyFields(replyTo, chat),
      });

      final senderName = chat.participantNames?[senderId] ?? 'User';
      await _sendPushNotification(
        receiverId: otherUid,
        senderName: senderName,
        messageText: '📷 Photo',
        chatId: chatId,
      );

      await chatRef.update({
        'lastMessage': '📷 Photo',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount.$otherUid': FieldValue.increment(1),
      });
    } catch (e) {
      print('sendImageMessage error: $e');
      _updatePendingMessage(
        chatId,
        messageId,
        (m) => m.copyWith(uploadFailed: true),
      );
    }
  }

  // Re-attempts a failed image send using the same local file. Creates a
  // fresh message id (simplest correct behavior — a retry is really just
  // a new attempt) and drops the old failed pending entry.
  Future<void> retryImageMessage(
    String chatId,
    String senderId,
    ChatMessage failedMessage,
  ) async {
    final path = failedMessage.localImagePath;
    if (path == null) return;
    _removePendingMessage(chatId, failedMessage.id);
    await sendImageMessage(chatId, senderId, File(path));
  }

  Future<Size> _readImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  void _addPendingMessage(String chatId, ChatMessage message) {
    final updated = Map<String, List<ChatMessage>>.from(
      state.pendingMessagesByChat,
    );
    updated[chatId] = [...(updated[chatId] ?? const []), message];
    emit(state.copyWith(pendingMessagesByChat: updated));
  }

  void _updatePendingMessage(
    String chatId,
    String messageId,
    ChatMessage Function(ChatMessage) update,
  ) {
    final list = state.pendingMessagesByChat[chatId];
    if (list == null) return;
    final updatedList = list
        .map((m) => m.id == messageId ? update(m) : m)
        .toList();
    final updated = Map<String, List<ChatMessage>>.from(
      state.pendingMessagesByChat,
    );
    updated[chatId] = updatedList;
    emit(state.copyWith(pendingMessagesByChat: updated));
  }

  void _removePendingMessage(String chatId, String messageId) {
    final list = state.pendingMessagesByChat[chatId];
    if (list == null) return;
    final updatedList = list.where((m) => m.id != messageId).toList();
    final updated = Map<String, List<ChatMessage>>.from(
      state.pendingMessagesByChat,
    );
    updated[chatId] = updatedList;
    emit(state.copyWith(pendingMessagesByChat: updated));
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
      0,
      (sum, chat) => sum + (chat.unreadCount[uid] ?? 0),
    );
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
    if (deliveredMs != null && deliveredMs >= msgMs)
      return MessageStatus.delivered;

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
      final userDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      if (!userDoc.exists) return;
      final token = userDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      await SendNotificationService().sendNotificationViaCloudFunction(
        title: senderName,
        body: messageText,
        deviceToken: token,
        data: {'type': 'chat', 'chatId': chatId},
      );
    } catch (e) {
      print('Push notification error: $e');
    }
  }
}

enum MessageStatus { sending, sent, delivered, seen }
