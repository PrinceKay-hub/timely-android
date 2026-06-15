
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class WorkingHours extends Equatable {
  final int startHour;
  final int endHour;
  final int startMinute;
  final int endMinute;

  const WorkingHours({
    required this.startHour,
    required this.endHour,
    required this.startMinute,
    required this.endMinute,
  });

 // AM/PM formatted strings
  String get formattedStartTime {
    final period = startHour >= 12 ? 'PM' : 'AM';
    final hour12 = startHour % 12;
    final displayHour = hour12 == 0 ? 12 : hour12;
    return '${displayHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} $period';
  }

  String get formattedEndTime {
    final period = endHour >= 12 ? 'PM' : 'AM';
    final hour12 = endHour % 12;
    final displayHour = hour12 == 0 ? 12 : hour12;
    return '${displayHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $period';
  }

  String get formattedRange => '$formattedStartTime - $formattedEndTime';

  TimeOfDay get startTimeOfDay => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTimeOfDay => TimeOfDay(hour: endHour, minute: endMinute);

  @override
  List<Object> get props => [startHour, endHour, startMinute, endMinute];
}



class ServiceEntity extends Equatable {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> workingDays;
  final WorkingHours workingHours;
  final int durationMinutes;
  final List<String> images;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final int workers;
  final List<Map<String, dynamic>> services;
  final String status;
  final List<String> amenities;
  final String number;
  final String region;
  final String district;

  const ServiceEntity({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    required this.workingDays,
    required this.workingHours,
    required this.durationMinutes,
    this.images = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.workers,
    required this.services,
    required this.status,
    required this.amenities,
    required this.number,
    required this.region,
    required this.district
  });

  ServiceEntity copyWith({
    String? id,
    String? providerId,
    String? name,
    String? description,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? workingDays,
    WorkingHours? workingHours,
    double? price,
    int? durationMinutes,
    List<String>? images,
    double? rating,
    int? totalReviews,
    DateTime? createdAt,
    int? workers,
    List<Map<String, dynamic>>? services,
    String? status,
    List<String>? amenities,
    String? number,
    String? region,
    String? district,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingDays: workingDays ?? this.workingDays,
      workingHours: workingHours ?? this.workingHours,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      workers: workers ?? this.workers,
      services: services ?? this.services,
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      number: number ?? this.number,
      region: region ?? this.region,
      district: district ?? this.district,
    );
  }

  @override
  List<Object?> get props => [
        id,
        providerId,
        name,
        description,
        category,
        location,
        latitude,
        longitude,
        workingDays,
        workingHours,
        durationMinutes,
        images,
        rating,
        totalReviews,
        createdAt,
        workers,
        services,
        status,
        amenities,
        number,
        region,
        district,
      ];
}