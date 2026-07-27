part of 'booking_form_cubit.dart';

class BookingFormState extends Equatable {
  final List<int> selectedServiceIndices;
  final DateTime selectedDate;
  final int selectedTimeIndex;
  final String selectedTimeString;
  final DateTime? selectedTimeDateTime;
  final bool isDateWorkingDay;
  final String? phone;

  const BookingFormState({
    this.selectedServiceIndices = const [],
    required this.selectedDate,
    this.selectedTimeIndex = -1,
    this.selectedTimeString = '',
    this.selectedTimeDateTime,
    required this.isDateWorkingDay,
    this.phone,
  });

  BookingFormState copyWith({
    List<int>? selectedServiceIndices,
    DateTime? selectedDate,
    int? selectedTimeIndex,
    String? selectedTimeString,
    DateTime? selectedTimeDateTime,
    String? totalPrice,
    bool? isDateWorkingDay,
    String? phone,
  }) {
    return BookingFormState(
      selectedServiceIndices: selectedServiceIndices ?? this.selectedServiceIndices,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeIndex: selectedTimeIndex ?? this.selectedTimeIndex,
      selectedTimeString: selectedTimeString ?? this.selectedTimeString,
      selectedTimeDateTime: selectedTimeDateTime ?? this.selectedTimeDateTime,
      isDateWorkingDay: isDateWorkingDay ?? this.isDateWorkingDay,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [
        selectedServiceIndices,
        selectedDate,
        selectedTimeIndex,
        selectedTimeString,
        selectedTimeDateTime,
        isDateWorkingDay,
        phone,
      ];
}