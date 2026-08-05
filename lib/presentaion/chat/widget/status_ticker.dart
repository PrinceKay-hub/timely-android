import 'package:booking/presentaion/chat/cubit_chat/chat_cubit.dart';
import 'package:flutter/material.dart';

class StatusTicks extends StatelessWidget {
  final MessageStatus status;

  const StatusTicks({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget icon;
    switch (status) {
      case MessageStatus.sending:
        icon = const Text('🕐', style: TextStyle(fontSize: 12));
        break;
      case MessageStatus.seen:
        icon = const Text(
          '✓✓',
          style: TextStyle(fontSize: 12, color: Colors.blue),
        );
        break;
      case MessageStatus.delivered:
        icon = const Text(
          '✓✓',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        );
        break;
      case MessageStatus.sent:
      default:
        icon = const Text(
          '✓',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        );
    }
    return icon;
  }
}