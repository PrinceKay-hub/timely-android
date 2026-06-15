
import 'package:equatable/equatable.dart';

enum ConnectivityStatus { online, offline, unknown }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  const ConnectivityState(this.status);

  const ConnectivityState.unknown() : this(ConnectivityStatus.unknown);
  const ConnectivityState.online() : this(ConnectivityStatus.online);
  const ConnectivityState.offline() : this(ConnectivityStatus.offline);

  @override
  List<Object> get props => [status];
}