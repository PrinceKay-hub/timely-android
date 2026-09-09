
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:booking/core/services/storage_service.dart';
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:equatable/equatable.dart';

part 'service_data_state.dart';

const int kServicePageSize = 20;
const int kMaxTotalServices = 60;

class ServiceDataCubit extends Cubit<ServiceDataState> {
  final ServiceRepositoryImpl serviceRepository;
  final StorageService storageService = StorageService();

  double? _anchor;
  bool _wrapped = false;
  double? _lastRandomValue;

  ServiceDataCubit(this.serviceRepository) : super(ServiceDataInitial());

  /// Loads the first page. Call this on pull-to-refresh too — it
  /// resets the pagination cursor.
  Future<void> fetchServiceData() async {
    emit(ServiceDataLoading());
    _anchor = Random().nextDouble(); // new random starting point per session
    _wrapped = false;
    _lastRandomValue = null;
    try {
      final result = await serviceRepository.getServicesPage(
        anchor: _anchor!,
        wrapped: _wrapped,
        lastRandomValue: _lastRandomValue,
        limit: kServicePageSize,
      );
      _wrapped = result.wrapped;
      _lastRandomValue = result.lastRandomValue;

      emit(ServiceDataLoaded(result.items, hasMore: result.hasMore));
    } catch (e) {
      emit(ServiceDataError('Failed to fetch service data'));
    }
  }

  /// Called when the UI scrolls near the bottom.
  Future<void> fetchNextPage() async {
    final current = state;
    if (current is! ServiceDataLoaded) return;
    if (!current.hasMore || current.isLoadingMore || _anchor == null) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final remaining = kMaxTotalServices - current.serviceData.length;
      final take = remaining < kServicePageSize ? remaining : kServicePageSize;
      if (take <= 0) {
        emit(current.copyWith(isLoadingMore: false, hasMore: false));
        return;
      }

      final result = await serviceRepository.getServicesPage(
        anchor: _anchor!,
        wrapped: _wrapped,
        lastRandomValue: _lastRandomValue,
        limit: take,
      );
      _wrapped = result.wrapped;
      _lastRandomValue = result.lastRandomValue;

      final combined = [...current.serviceData, ...result.items];
      emit(ServiceDataLoaded(
        combined,
        hasMore: combined.length < kMaxTotalServices && result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }


  Future<void> deleteServiceImage(String imageUrl, String serviceId) async {
    emit(ServiceDataLoading());
    try {
      await storageService.deleteImage(imageUrl, serviceId);
      emit(ServiceDataUpdateSuccess());
    } catch (e) {
      emit(ServiceDataError('Failed to delete service data'));
    }
  }
}