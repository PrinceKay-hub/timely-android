import 'package:bloc/bloc.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();

  ConnectivityCubit() : super(const ConnectivityState.unknown()) {
    _init();
  }

  Future<void> _init() async {
    // Get initial connectivity status (returns a list)
    final results = await _connectivity.checkConnectivity();
    emit(_mapResultsToState(results));

    // Listen to changes (now also returns a list)
    _connectivity.onConnectivityChanged.listen((results) {
      emit(_mapResultsToState(results));
    });
  }

  /// Convert a list of ConnectivityResult into a single ConnectivityState
  ConnectivityState _mapResultsToState(List<ConnectivityResult> results) {
    // Offline if the list contains ConnectivityResult.none
    final isOffline = results.contains(ConnectivityResult.none);
    return isOffline
        ? const ConnectivityState.offline()
        : const ConnectivityState.online();
  }
}