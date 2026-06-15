// detail_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:booking/presentaion/screens/home/detail/cubit/detail_state.dart';


class DetailCubit extends Cubit<DetailState> {
  DetailCubit() : super(const DetailState());

  void updateImageIndex(int index) {
    emit(state.copyWith(currentImageIndex: index));
  }

  void setLoadingDirections(bool isLoading) {
    emit(state.copyWith(isLoadingDirections: isLoading));
  }
}