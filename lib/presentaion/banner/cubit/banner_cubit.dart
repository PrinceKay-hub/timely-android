import 'dart:async';
import 'package:booking/data/models/baner_model.dart';
import 'package:booking/data/repositories/banner_repository.dart';
import 'package:booking/presentaion/banner/cubit/banner_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BannerCubit extends Cubit<BannerState> {
  final BannerRepository _repository;
  StreamSubscription<List<BannerModel>>? _subscription;

  BannerCubit({BannerRepository? repository})
      : _repository = repository ?? BannerRepository(),
        super(const BannerInitial());

  void subscribe() {
    emit(const BannerLoading());
    _subscription?.cancel();
    _subscription = _repository.watchActiveBanners().listen(
      (banners) => emit(BannerLoaded(banners)),
      onError: (error, _) => emit(BannerError(error.toString())),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}