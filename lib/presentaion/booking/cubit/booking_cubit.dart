import 'dart:async';
import 'package:booking/core/services/send_notification.dart';
import 'package:booking/domain/entities/booking_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:booking/domain/repositories/booking_repository.dart';
import 'package:booking/domain/repositories/user_repository.dart';
import 'package:booking/core/services/local_notification_service.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository bookingRepository;
  final UserRepository userRepository;
  final LocalNotificationService notificationService;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  BookingCubit({
    required this.bookingRepository,
    required this.userRepository,
    required this.notificationService,
  }) : super(BookingInitial());



  // In your BookingCubit
Future<void> createBooking(BookingEntity bookingData) async {
  emit(BookingLoading());
  
  try {
    // Validate required fields
    if (bookingData.serviceId.isEmpty) {
      emit(BookingError('Service is required'));
      return;
    }
    
    await bookingRepository.createBooking(bookingData);

    emit(BookingConfirmation(bookingData));

    sendnotification(bookingData.providerId, 'New Appointment', 'Open app for more details');

    emit(BookingSuccess(bookingId: bookingData.id, message: 'Check back later for confirmation from Service Provider'));
    
  } catch (e) {
    emit(BookingError('An error occurred: ${e.toString()}'));
  }
}

// Start listening to the real‑time stream
  void listenToUserBookings(String userId) {
    // Cancel any previous subscription
    _subscription?.cancel();

    emit(BookingLoading());

    final stream =  bookingRepository.getUserBookings(userId);
    _subscription = stream.listen(
      (bookings) {
        emit(BookingLoaded(bookings));
      },
      onError: (error) {
        emit(BookingError('Failed to load bookings: $error'));
      },
    );
  }


/*Future<void> fetchUserBookings(String userId) async {
    // Don't emit loading if we're already loading
    if (state is BookingLoading) return;

    emit(BookingLoading());

    try {
      final bookings = await bookingRepository.getUserBookings(userId);
      emit(BookingLoaded(bookings));
    } catch (e) {
      emit(BookingError('Failed to load bookings: ${e.toString()}'));
    }
  }*/

  Future<void> confirmBooking(String bookingId, String userId) async {
    try {

      emit(BookingLoading());
      
      // Confirm booking in database
      await bookingRepository.confirmBooking(bookingId);
      
      sendnotification(userId, 'Appointment Confirmed ✅', 'Your appointment has been confirmed',);

      emit(BookingSuccess(
        bookingId: bookingId,
        message: 'Booking confirmed successfully!',
      ));
      
    } catch (e) {
      emit(BookingError('Failed to confirm booking: $e'));
    }
  }

  Future<void> cancelBooking(String bookingId, reason, userId) async {
    try {
      emit(BookingLoading());
      
      await bookingRepository.cancelBooking(bookingId, reason);

      sendnotification(userId, 'Appointment Cancelled ❌', 'Your appointment has been cancelled. Open app for more details',);
      
      emit(BookingSuccess(
        bookingId: bookingId,
        message: 'Booking cancelled successfully',
      ));
      
    } catch (e) {
      emit(BookingError('Failed to cancel booking: $e'));
    }
  }

  Future<void> updateBooking(String bookingId, DateTime appointmentDate, TimeSlot timeSlot) async {
    try {
      emit(BookingLoading());
      
      await bookingRepository.updateBooking(bookingId, appointmentDate, timeSlot);
      
      emit(BookingSuccess(
        bookingId: bookingId,
        message: 'Booking Reschedule successfully',
      ));
      
    } catch (e) {
      emit(BookingError('Failed to update booking: $e'));
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      
      emit(BookingLoading());

      await bookingRepository.deleteBooking(bookingId);


    emit(BookingSuccess(
      bookingId: bookingId, 
      message: 'Booking deleted successfully')
    );
    } catch (e) {
      emit(BookingError('Failed to delete booking: $e'));
    }
  }


  void sendnotification(String userIDs, title, body) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userIDs)
        .get();

    String token = snapshot['fcmToken'];

    SendNotificationService().sendNotificationViaCloudFunction(
      title: title,
      body: body,
      deviceToken: token,
    );
  }

  // Clean up when the cubit is disposed
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}