import 'package:booking/data/models/baner_model.dart';

sealed class BannerState {
  const BannerState();
}

class BannerInitial extends BannerState {
  const BannerInitial();
}

class BannerLoading extends BannerState {
  const BannerLoading();
}

class BannerLoaded extends BannerState {
  final List<BannerModel> banners;
  const BannerLoaded(this.banners);
}

class BannerError extends BannerState {
  final String message;
  const BannerError(this.message);
}