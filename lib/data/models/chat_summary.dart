import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ChatSummary extends Equatable {
  final String id;
  final List<String> participants;
  final Map<String, String>? participantNames;
  final Map<String, String>? participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, int> unreadCount; 
  final Map<String, DateTime>? deliveredTo;
  final Map<String, DateTime>? readTo;
  final DateTime? createdAt;
  final String? serviceId;
  final String? serviceName;
  final String? providerId;

  const ChatSummary({
    required this.id,
    required this.participants,
    this.participantNames,
    this.participantPhotos,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.unreadCount = const {},
    this.deliveredTo,
    this.readTo,
    this.createdAt,
    this.serviceId,
    this.serviceName,
    this.providerId,
  });

  factory ChatSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSummary(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: Map<String, String>.from(data['participantPhotos'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      deliveredTo: _mapTimestamps(data['deliveredTo']),
      readTo: _mapTimestamps(data['readTo']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      serviceId: data['serviceId'],
      serviceName: data['serviceName'],
      providerId: data['providerId'],
    );
  }

  static Map<String, DateTime>? _mapTimestamps(Map? map) {
    if (map == null) return null;
    final result = <String, DateTime>{};
    map.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate();
      }
    });
    return result;
  }

  @override
  List<Object?> get props => [
    id,
    participants,
    participantNames,
    participantPhotos,
    lastMessage,
    lastMessageAt,
    lastSenderId,
    unreadCount,
    deliveredTo,
    readTo,
    createdAt,
    serviceId,
    serviceName,
    providerId,
  ];
}