import 'package:booking/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Future<String> createBooking(BookingEntity booking);
  
  Future<void> cancelBooking(String bookingId, String reason);

  Future<void> confirmBooking(String bookingId);

  Future<void> deleteBooking(String bookingId);
  
  Stream<List<Map<String, dynamic>>> getUserBookings(String userId);

  Future<void> updateBooking(String bookingId, DateTime appointmentDate, TimeSlot timeSlot);
}