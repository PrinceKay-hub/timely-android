import 'package:booking/data/models/portfolio_model.dart';
import 'package:equatable/equatable.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();
  @override
  List<Object> get props => [];
}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioImage> images;
  const PortfolioLoaded(this.images);
  @override
  List<Object> get props => [images];
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError(this.message);
  @override
  List<Object> get props => [message];
}
