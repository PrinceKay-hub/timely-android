part of 'service_data_cubit.dart';

sealed class ServiceDataState extends Equatable {
  const ServiceDataState();

  @override
  List<Object> get props => [];
}

final class ServiceDataInitial extends ServiceDataState {}

final class ServiceDataLoading extends ServiceDataState {}

final class ServiceDataLoaded extends ServiceDataState {
  final List serviceData;

  const ServiceDataLoaded(this.serviceData);

  @override
  List<Object> get props => [serviceData];
}

final class ServiceByIdDataLoaded extends ServiceDataState {
  final Map<String, dynamic> serviceData;

  const ServiceByIdDataLoaded(this.serviceData);

  @override
  List<Object> get props => [serviceData];
}

final class ServiceDataUpdateSuccess extends ServiceDataState {}

final class ServiceDataError extends ServiceDataState {
  final String message;

  const ServiceDataError(this.message);

  @override
  List<Object> get props => [message];
}