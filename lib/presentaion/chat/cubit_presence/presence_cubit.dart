import 'dart:async';
import 'package:booking/data/models/presence_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'presence_state.dart';

class PresenceCubit extends Cubit<PresenceState> {
  PresenceCubit() : super(const PresenceState());

  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();

  // Own presence subscription (root level)
  StreamSubscription<DatabaseEvent>? _ownPresenceSubscription;

  // Map from uid to subscription for observed users
  final Map<String, StreamSubscription<DatabaseEvent>> _subscriptions = {};

  String? _ownUid;

  void startOwnPresence(String uid) {
    _ownUid = uid;
    final myStatusRef = _rtdb.child('status/$uid');
    final connectedRef = _rtdb.child('.info/connected');

    _ownPresenceSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) return;

      myStatusRef.onDisconnect().set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      }).then((_) {
        myStatusRef.set({
          'state': 'online',
          'lastSeen': ServerValue.timestamp,
        });
      }).catchError((e) {
        print('Failed to arm presence onDisconnect: $e');
      });
    });
  }

  // No parameter needed – uses stored _ownUid
  void stopOwnPresence() {
    if (_ownUid != null) {
      _rtdb.child('status/$_ownUid').set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
      }).catchError((_) {});
      _ownPresenceSubscription?.cancel();
      _ownPresenceSubscription = null;
      _ownUid = null;
    }
  }

  void disposeAll() {
    stopOwnPresence();
    // cancel all observed users subscriptions
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    emit(const PresenceState());
  }

  /// Subscribe to another user's presence.
  void subscribeToPresence(String uid) {
    if (_subscriptions.containsKey(uid)) return;

    final statusRef = _rtdb.child('status/$uid');
    final sub = statusRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      PresenceInfo info;
      if (data != null) {
        final state = data['state'] == 'online' ? 'online' : 'offline';
        final lastSeen = data['lastSeen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int)
            : null;
        info = PresenceInfo(state: state, lastSeen: lastSeen);
      } else {
        info = const PresenceInfo(state: 'offline');
      }
      final updated = Map<String, PresenceInfo>.from(state.presenceByUid);
      updated[uid] = info;
      emit(state.copyWith(presenceByUid: updated));
    });

    _subscriptions[uid] = sub;
  }

  /// Unsubscribe from a user's presence.
  void unsubscribeFromPresence(String uid) {
    _subscriptions[uid]?.cancel();
    _subscriptions.remove(uid);
  }

  /// Get current presence info for a uid (synchronous read).
  PresenceInfo? getPresence(String uid) {
    return state.presenceByUid[uid];
  }
}

/// Helper to format presence label (e.g., "Online", "Last seen 5m ago")
String formatPresenceLabel(PresenceInfo? presence) {
  if (presence == null) return '';
  if (presence.state == 'online') return 'Online';
  if (presence.lastSeen == null) return '';
  final diff = DateTime.now().difference(presence.lastSeen!);
  final minutes = diff.inMinutes;
  if (minutes < 1) return 'Last seen just now';
  if (minutes < 60) return 'Last seen $minutes m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'Last seen $hours h ago';
  final days = hours ~/ 24;
  if (days < 7) return 'Last seen $days d ago';
  return 'Last seen a while ago';
}