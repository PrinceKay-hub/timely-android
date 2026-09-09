part of 'service_data_cubit.dart';

sealed class ServiceDataState extends Equatable {
  const ServiceDataState();

  @override
  List<Object> get props => [];
}

final class ServiceDataInitial extends ServiceDataState {}

final class ServiceDataLoading extends ServiceDataState {}

class ServiceDataLoaded extends ServiceDataState {
  final List serviceData;
  final bool hasMore;
  final bool isLoadingMore;
 
  const ServiceDataLoaded(
    this.serviceData, {
    this.hasMore = true,
    this.isLoadingMore = false,
  });
 
  ServiceDataLoaded copyWith({
    List? serviceData,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ServiceDataLoaded(
      serviceData ?? this.serviceData,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
 
  @override
  List<Object> get props => [serviceData, hasMore, isLoadingMore];
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
