import 'package:booking/domain/entities/booking_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.serviceId,
    required super.serviceName,
    required super.providerId,
    required super.userId,
    required super.appointmentDate,
    required super.timeSlot,
    required super.serviceOption,
    required super.totalAmount,
    super.status = 'pending',
    required super.createdAt,
    required super.userName,
    required super.participants,
    required super.latitude,
    required super.longitude,
    required super.workingDays,
    required super.workingHours,
    required super.services,
    super.reminderSent = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      providerId: json['providerId'] ?? '',
      userId: json['userId'] ?? '',
      appointmentDate: (json['appointmentDate'] as Timestamp).toDate(),
      timeSlot: TimeSlot(
        displayTime: json['timeSlot']['displayTime'] ?? '',
        time: (json['timeSlot']['time'] as Timestamp).toDate(),
      ),
      serviceOption: ServiceOption(
        title: json['serviceOption']['title'] ?? '',
        price: (json['serviceOption']['price'] ?? 0.0).toDouble(),
        durationMinutes: json['serviceOption']['durationMinutes'] ?? 60,
      ),
      totalAmount: (json['totalAmount'] ?? 0),
      status: json['status'] ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      userName: json['userName'] ?? '',
      participants: json['participants'] ?? [],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 0.0,
      workingDays: json['workingDays'] ?? [],
      workingHours: json['workingHours'] ?? {},
      services: List.from(json['services'] ?? []),
      reminderSent: json['reminderSent'] ?? false
    );
  }

  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      serviceId: entity.serviceId,
      serviceName: entity.serviceName,
      providerId: entity.providerId,
      userId: entity.userId,
      appointmentDate: entity.appointmentDate,
      timeSlot: entity.timeSlot,
      serviceOption: entity.serviceOption,
      totalAmount: entity.totalAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      userName: entity.userName,
      participants: entity.participants,
      latitude: entity.latitude,
      longitude: entity.longitude,
      workingDays: entity.workingDays,
      workingHours: entity.workingHours,
      services: entity.services,
      reminderSent: entity.reminderSent
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'providerId': providerId,
      'userId': userId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': {
        'displayTime': timeSlot.displayTime,
        'time': Timestamp.fromDate(timeSlot.time),
      },
      'serviceOption': {
        'title': serviceOption.title,
        'price': serviceOption.price,
        'durationMinutes': serviceOption.durationMinutes,
      },
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'userName': userName,
      'participants': participants,
      'latitude': latitude,
      'longitude': longitude,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'services': services,
      'reminderSent': reminderSent
    };
  }

  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      serviceId: serviceId,
      serviceName: serviceName,
      providerId: providerId,
      userId: userId,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      serviceOption: serviceOption,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      userName: userName,
      participants: participants,
      latitude: latitude,
      longitude: longitude,
      workingDays: workingDays,
      workingHours: workingHours,
      services: services,
      reminderSent: reminderSent
    );
  }
}