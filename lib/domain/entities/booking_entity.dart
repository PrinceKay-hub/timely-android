import 'package:equatable/equatable.dart';


class ServiceOption extends Equatable {
  final String title;
  final int price;
  final int durationMinutes;

  const ServiceOption({
    required this.title,
    required this.price,
    required this.durationMinutes,
  });

  @override
  List<Object> get props => [ title, price, durationMinutes];
}

class TimeSlot extends Equatable {
  final String displayTime;
  final DateTime time;

  const TimeSlot({
    required this.displayTime,
    required this.time,
  });

  @override
  List<Object> get props => [ displayTime, time, ];
}

class BookingEntity extends Equatable {
  final String id;
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String userId;
  final DateTime appointmentDate;
  final TimeSlot timeSlot;
  final ServiceOption serviceOption;
  final int totalAmount;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime createdAt;
  final String userName;
  final List participants;
  final double latitude;
  final double longitude;
  final List workingDays;
  final Map<String, dynamic> workingHours;
  final List<Map<String, dynamic>> services;
  final bool reminderSent;

  const BookingEntity({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.userId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.serviceOption,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
    required this.userName,
    required this.participants,
    required this.latitude,
    required this.longitude,
    required this.workingDays,
    required this.workingHours,
    required this.services, 
    this.reminderSent = false,
  });

  @override
  List<Object> get props => [
    id,
    serviceId,
    serviceName,
    providerId,
    userId,
    appointmentDate,
    timeSlot,
    serviceOption,
    totalAmount,
    status,
    createdAt,
    userName,
    participants,
    latitude,
    longitude,
    workingDays,
    workingHours,
    services,
    reminderSent
  ];
}