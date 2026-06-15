part of 'service_detail_cubit.dart';

sealed class ServiceDetailState extends Equatable {
  const ServiceDetailState();

  @override
  List<Object> get props => [];
}

final class ServiceDetailInitial extends ServiceDetailState {}

final class ServiceDetailLoading extends ServiceDetailState {}

final class ServiceDetailError extends ServiceDetailState {
  final String message;

  const ServiceDetailError(this.message);

  @override
  List<Object> get props => [message];
}

final class ServiceDetailLoaded extends ServiceDetailState {
  final Map<String, dynamic> serviceData;

  const ServiceDetailLoaded(this.serviceData);

  @override
  List<Object> get props => [serviceData];
}
