import 'dart:io';

import 'package:booking/data/models/chat_message.dart';
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:booking/presentaion/chat/widget/image_viewer_screen.dart';
import 'package:booking/presentaion/chat/widget/status_ticker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String chatId;
  final ValueChanged<ChatMessage> onReply;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.chatId,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final myUid = authState.user.id;
    final isMine = message.senderId == myUid;

    final chat = context.watch<ChatCubit>().state.chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => throw Exception('Chat not found'),
    );
    final status = ChatCubit.getMessageStatus(message, chat, myUid);

    if (message.isDeletedFor(myUid)) {
      return _DeletedBubble(isMine: isMine);
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(context, myUid, isMine),
      child: _SwipeToReply(
        onReply: () => onReply(message),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              message.type == MessageType.image
                  ? _ImageBubble(message: message, chatId: chatId, isMine: isMine, status: status)
                  : _TextBubble(message: message, isMine: isMine, status: status),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, String myUid, bool isMine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onReply(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.read<ChatCubit>().deleteMessageForMe(chatId, message.id, myUid);
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.read<ChatCubit>().deleteMessageForEveryone(chatId, message.id, myUid);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMine;
  const _DeletedBubble({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.block, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text('This message was deleted',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Drag-and-snap-back gesture. Deliberately not Dismissible — we never
// want the item removed from the list, just a reply icon revealed on
// a partial rightward drag, same as WhatsApp/Telegram.
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const _SwipeToReply({required this.child, required this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dragExtent = 0;
  static const double _triggerThreshold = 60;
  bool _triggered = false;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(0, 80).toDouble();
      if (_dragExtent >= _triggerThreshold && !_triggered) {
        _triggered = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent >= _triggerThreshold) {
      widget.onReply();
    }
    setState(() {
      _dragExtent = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dragExtent > 0)
            Opacity(
              opacity: (_dragExtent / _triggerThreshold).clamp(0, 1),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.reply, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: Matrix4.translationValues(_dragExtent, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _QuotedReply extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _QuotedReply({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isImage = message.replyToType == MessageType.image;
    final barColor = isMine ? Colors.white : Theme.of(context).colorScheme.primary;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final myUid = authState.user.id;
    final isReplToMe = message.replyToSenderId == myUid;
    final senderLabel = isReplToMe ? 'You' : (message.replyToSenderName ?? 'Unknown');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: barColor, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (senderLabel.isNotEmpty)
                  Text(
                    senderLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                Text(
                  isImage ? '📷 Photo' : (message.replyToText ?? 'Message unavailable'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMine ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (isImage && message.replyToImageUrl != null) ...[
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: message.replyToImageUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final MessageStatus status;

  const _TextBubble({required this.message, required this.isMine, required this.status});

  @override
  Widget build(BuildContext context) {
    final timeStamp = message.createdAt;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.replyToId != null) _QuotedReply(message: message, isMine: isMine),
          Text(
            message.text,
            style: TextStyle(
              color: isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStamp != null ? DateFormat.jm().format(timeStamp) : 'Sending...',
                style: TextStyle(
                  fontSize: 10,
                  color: isMine ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 5),
              if (isMine) StatusTicks(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final ChatMessage message;
  final String chatId;
  final bool isMine;
  final MessageStatus status;

  const _ImageBubble({
    required this.message,
    required this.chatId,
    required this.isMine,
    required this.status,
  });

  double get _aspectRatio {
    final w = message.imageWidth;
    final h = message.imageHeight;
    if (w != null && h != null && h > 0) {
      return (w / h).clamp(0.6, 1.6);
    }
    return 4 / 3;
  }

  bool get _isLocal => message.imageUrl == null && message.localImagePath != null;

  bool get _isUploading =>
      !message.uploadFailed && message.uploadProgress != null && message.uploadProgress! < 1.0;

  void _openViewer(BuildContext context) {
    if (message.imageUrl == null && message.localImagePath == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImageViewerScreen(
          heroTag: message.id,
          imageUrl: message.imageUrl,
          localImagePath: message.localImagePath,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _retry(BuildContext context) {
    context.read<ChatCubit>().retryImageMessage(chatId, message.senderId, message);
  }

  @override
  Widget build(BuildContext context) {
    final timeStamp = message.createdAt;
    final isMine_ = isMine; // keep for the quoted-reply reuse below

    return Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.replyToId != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: _QuotedReply(message: message, isMine: isMine_),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: GestureDetector(
              onTap: message.uploadFailed ? () => _retry(context) : () => _openViewer(context),
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: message.id,
                      child: _isLocal
                          ? Image.file(File(message.localImagePath!), fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 150),
                              placeholder: (_, __) => Container(color: Colors.grey.shade300),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                              ),
                            ),
                    ),
                    if (_isUploading)
                      Container(
                        color: Colors.black.withOpacity(0.35),
                        child: Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: message.uploadProgress,
                              strokeWidth: 3,
                              color: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    if (message.uploadFailed)
                      Container(
                        color: Colors.black.withOpacity(0.45),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text('Tap to retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStamp != null ? DateFormat.jm().format(timeStamp) : '',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              StatusTicks(status: status),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}