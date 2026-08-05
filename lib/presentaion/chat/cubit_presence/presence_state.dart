import 'package:booking/data/models/presence_info.dart';
import 'package:equatable/equatable.dart';

class PresenceState extends Equatable {
  final Map<String, PresenceInfo> presenceByUid;

  const PresenceState({this.presenceByUid = const {}});

  PresenceState copyWith({Map<String, PresenceInfo>? presenceByUid}) {
    return PresenceState(presenceByUid: presenceByUid ?? this.presenceByUid);
  }

  @override
  List<Object?> get props => [presenceByUid];
}