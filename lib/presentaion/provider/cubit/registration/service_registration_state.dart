
import 'package:booking/domain/entities/service_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ServiceRegistrationState extends Equatable {
  const ServiceRegistrationState();

  @override
  List<Object> get props => [];
}

class ServiceRegistrationInitial extends ServiceRegistrationState {}

class ServiceRegistrationLoading extends ServiceRegistrationState {}

class ServiceRegistrationSuccess extends ServiceRegistrationState {}

class ServiceDeletionSuccess extends ServiceRegistrationState {}

class ServiceRegistrationError extends ServiceRegistrationState {
  final String message;

  const ServiceRegistrationError(this.message);

  @override
  List<Object> get props => [message];
}

final class ServiceRegistrationDataLoaded extends ServiceRegistrationState {
  final Map<String, dynamic>? serviceData;

  const ServiceRegistrationDataLoaded(this.serviceData);

  @override
  List<Object> get props => [?serviceData];
}


class ServiceRegistrationUpdated extends ServiceRegistrationState {
  final ServiceEntity service;

  const ServiceRegistrationUpdated(
    this.service,
  );

  @override
  List<Object> get props => [service];
}