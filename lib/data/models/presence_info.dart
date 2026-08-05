import 'package:equatable/equatable.dart';

class PresenceInfo extends Equatable {
  final String state; // 'online' or 'offline'
  final DateTime? lastSeen;

  const PresenceInfo({required this.state, this.lastSeen});

  @override
  List<Object?> get props => [state, lastSeen];
}