import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // or your navigation


class MessageButton extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserPhoto;
  final String? serviceId;
  final String? serviceName;
  final String label;

  const MessageButton({
    Key? key,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserPhoto,
    this.serviceId,
    this.serviceName,
    this.label = 'Message',
  }) : super(key: key);

  @override
  State<MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<MessageButton> {
  bool _loading = false;

  Future<void> _handlePress() async {
    final authState = context.read<AuthCubit>().state; // assuming you have auth cubit
    if (authState is! AuthAuthenticated || authState is! AuthAuthenticatedGoog) return;
    final user = authState.user;

    setState(() => _loading = true);
    try {
      final chatCubit = context.read<ChatCubit>();
      final chatId = await chatCubit.getOrCreateChat(
        currentUserId: user.id,
        currentUserName: user.displayName,
        currentUserPhoto: user.photoUrl,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        otherUserPhoto: widget.otherUserPhoto,
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
      );
      // Navigate to chat screen
      context.push('/chat/$chatId');
    } catch (e) {
      print('Failed to open chat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: _loading ? null : _handlePress,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.chat_bubble_outline, size: 20),
      label: Text(_loading ? '' : widget.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}