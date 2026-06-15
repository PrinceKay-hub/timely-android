import 'package:booking/domain/entities/service_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.providerId,
    required super.name,
    required super.description,
    required super.category,
    required super.location,
    super.latitude,
    super.longitude,
    required super.workingDays,
    required super.workingHours,
    required super.durationMinutes,
    super.images = const [],
    super.rating = 0.0,
    super.totalReviews = 0,
    required super.createdAt,
    required super.workers,
    required super.services,
    required super.status,
    required super.amenities,
    required super.number,
    required super.region,
    required super.district
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      workingDays: List<String>.from(json['workingDays'] ?? []),
      workingHours: WorkingHours(
        startHour: json['workingHours']['startHour'] ?? 9,
        endHour: json['workingHours']['endHour'] ?? 17,
        startMinute: json['workingHours']['startMinute'] ?? 0,
        endMinute: json['workingHours']['endMinute'] ?? 0,
      ),
      durationMinutes: json['durationMinutes'] ?? 60,
      images: List<String>.from(json['images'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      workers: json['workers'] ?? 1,
      services: List.from(json['services'] ?? []),
      status: json['status'] ?? '',
      amenities: List.from(json['amenities'] ?? []),
      number: json['number'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
    );
  }

  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      providerId: entity.providerId,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      workingDays: entity.workingDays,
      workingHours: entity.workingHours,
      durationMinutes: entity.durationMinutes,
      images: entity.images,
      rating: entity.rating,
      totalReviews: entity.totalReviews,
      createdAt: entity.createdAt,
      workers: entity.workers,
      services: entity.services,
      status: entity.status,
      amenities: entity.amenities,
      number: entity.number,
      region: entity.region,
      district: entity.district
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'name': name,
      'description': description,
      'category': category,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'workingDays': workingDays,
      'workingHours': {
        'startHour': workingHours.startHour,
        'endHour': workingHours.endHour,
        'startMinute': workingHours.startMinute,
        'endMinute': workingHours.endMinute,
      },
      'images': images,
      'rating': rating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'workers': workers,
      'services': services,
      'status': status,
      'amenities': amenities,
      'number': number,
      'region': region,
      'district': district,
    };
  }

  ServiceEntity toEntity() {
    return ServiceEntity(
      id: id,
      providerId: providerId,
      name: name,
      description: description,
      category: category,
      location: location,
      latitude: latitude,
      longitude: longitude,
      workingDays: workingDays,
      workingHours: workingHours,
      durationMinutes: durationMinutes,
      images: images,
      rating: rating,
      totalReviews: totalReviews,
      createdAt: createdAt,
      workers: workers,
      services: services,
      status: status,
      amenities: amenities,
      number: number,
      region: region,
      district: district
    );
  }
}