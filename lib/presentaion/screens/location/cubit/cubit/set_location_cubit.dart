import 'package:bloc/bloc.dart';

part 'set_location_state.dart';

class SetLocationCubit extends Cubit<SetLocationState> {
  SetLocationCubit() : super(SetLocationState('Select Location'));

  void saveString(String newValue) {
    emit(SetLocationState(newValue));
  }
}
