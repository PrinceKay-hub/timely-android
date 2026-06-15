part of 'booking_form_cubit.dart';

class BookingFormState extends Equatable {
  final int? selectedServiceIndex;
  final DateTime selectedDate;
  final int selectedTimeIndex;
  final String selectedTimeString;
  final DateTime? selectedTimeDateTime;
  final int totalPrice;
  final bool isDateWorkingDay;

  const BookingFormState({
    this.selectedServiceIndex,
    required this.selectedDate,
    this.selectedTimeIndex = -1,
    this.selectedTimeString = '',
    this.selectedTimeDateTime,
    this.totalPrice = 0,
    required this.isDateWorkingDay,
  });

  BookingFormState copyWith({
    int? selectedServiceIndex,
    DateTime? selectedDate,
    int? selectedTimeIndex,
    String? selectedTimeString,
    DateTime? selectedTimeDateTime,
    int? totalPrice,
    bool? isDateWorkingDay,
  }) {
    return BookingFormState(
      selectedServiceIndex: selectedServiceIndex ?? this.selectedServiceIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeIndex: selectedTimeIndex ?? this.selectedTimeIndex,
      selectedTimeString: selectedTimeString ?? this.selectedTimeString,
      selectedTimeDateTime: selectedTimeDateTime ?? this.selectedTimeDateTime,
      totalPrice: totalPrice ?? this.totalPrice,
      isDateWorkingDay: isDateWorkingDay ?? this.isDateWorkingDay,
    );
  }

  @override
  List<Object?> get props => [
        selectedServiceIndex,
        selectedDate,
        selectedTimeIndex,
        selectedTimeString,
        selectedTimeDateTime,
        totalPrice,
        isDateWorkingDay,
      ];
}