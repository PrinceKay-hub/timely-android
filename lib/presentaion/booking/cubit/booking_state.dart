part of 'booking_cubit.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<Map<String, dynamic>> bookings;

  const BookingLoaded(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingConfirmation extends BookingState {
  final BookingEntity booking;
  
  const BookingConfirmation(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingSuccess extends BookingState {
  final String bookingId;
  final String message;

  const BookingSuccess({required this.bookingId, required this.message});

  @override
  List<Object> get props => [bookingId, message];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object> get props => [message];
}

