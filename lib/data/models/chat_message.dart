import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, image }

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;
  final bool pending;
  final MessageType type;

  // Image-specific fields — persisted to Firestore once the upload completes.
  final String? imageUrl;
  final double? imageWidth;
  final double? imageHeight;

  // Local-only fields — NEVER read from or written to Firestore. These
  // exist purely to render the optimistic bubble while an image uploads.
  // See ChatCubit.sendImageMessage.
  final String? localImagePath;
  final double? uploadProgress; // 0.0–1.0 while uploading, null once resolved
  final bool uploadFailed;

  final bool isDeleted;
  final List<String>? deletedFor; // uids who "deleted for me"
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final MessageType? replyToType;
  final String? replyToImageUrl;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
    this.pending = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    this.localImagePath,
    this.uploadProgress,
    this.uploadFailed = false,
    this.isDeleted = false,
    this.deletedFor,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToType,
    this.replyToImageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'] as Timestamp?;
    final typeStr = data['type'] as String?;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: ts?.toDate(),
      pending: doc.metadata.hasPendingWrites,
      type: typeStr == 'image' ? MessageType.image : MessageType.text,
      imageUrl: data['imageUrl'] as String?,
      imageWidth: (data['imageWidth'] as num?)?.toDouble(),
      imageHeight: (data['imageHeight'] as num?)?.toDouble(),
      isDeleted: data['isDeleted'] ?? false,
      deletedFor: data['deletedFor'] != null ? List<String>.from(data['deletedFor']) : null,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSenderId: data['replyToSenderId'],
      replyToSenderName: data['replyToSenderName'],
      replyToType: data['replyToType'] == 'image' ? MessageType.image : (data['replyToType'] == 'text' ? MessageType.text : null),
      replyToImageUrl: data['replyToImageUrl'],
    );
  }

  ChatMessage copyWith({
    DateTime? createdAt,
    bool? pending,
    String? imageUrl,
    double? uploadProgress,
    bool? uploadFailed,
    bool? isDeleted,
    List<String>? deletedFor,
    String? replyToId,
    String? replyToText,
    String? replyToSenderId,
    String? replyToSenderName,
    MessageType? replyToType,
    String? replyToImageUrl,
  }) {
    
    return ChatMessage(
      id: id,
      senderId: senderId,
      text: text,
      createdAt: createdAt ?? this.createdAt,
      pending: pending ?? this.pending,
      type: type,
      imageUrl: imageUrl ?? this.imageUrl,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      localImagePath: localImagePath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadFailed: uploadFailed ?? this.uploadFailed,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToType: replyToType ?? this.replyToType,
      replyToImageUrl: replyToImageUrl ?? this.replyToImageUrl,
    );
  }
  bool isDeletedFor(String uid) => isDeleted || (deletedFor?.contains(uid) ?? false);
  @override
  List<Object?> get props => [
        id,
        senderId,
        text,
        createdAt,
        pending,
        type,
        imageUrl,
        imageWidth,
        imageHeight,
        localImagePath,
        uploadProgress,
        uploadFailed,
        isDeleted,
        deletedFor,
        replyToId,
        replyToText,
        replyToSenderId,
        replyToSenderName,
        replyToType,
        replyToImageUrl,
      ];
}