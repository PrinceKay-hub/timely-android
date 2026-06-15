import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'booking_form_state.dart';

class BookingFormCubit extends Cubit<BookingFormState> {
  final Map<String, dynamic> providerData;
  final List<Map<String, dynamic>> services;

  BookingFormCubit({
    required this.providerData,
    required this.services,
  }) : super(
          BookingFormState(
            selectedDate: _getInitialDate(providerData),
            isDateWorkingDay: _checkIfWorkingDay(
              _getInitialDate(providerData),
              providerData,
            ),
          ),
        );

  // Helper methods (same as before)
  static DateTime _getInitialDate(Map<String, dynamic> providerData) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final workingDayNumbers = _getWorkingDayNumbers(providerData);
    if (workingDayNumbers.contains(todayDateOnly.weekday)) {
      return todayDateOnly;
    }
    // Find first working day of current month
    //final firstOfMonth = DateTime(today.year, today.month, 1);
    for (int day = 1; day <= DateTime(today.year, today.month + 1, 0).day; day++) {
      final date = DateTime(today.year, today.month, day);
      if (workingDayNumbers.contains(date.weekday)) {
        return date;
      }
    }
    return todayDateOnly; // fallback
  }

  static bool _checkIfWorkingDay(DateTime date, Map<String, dynamic> providerData) {
    final workingDayNumbers = _getWorkingDayNumbers(providerData);
    return workingDayNumbers.contains(date.weekday);
  }

  static Set<int> _getWorkingDayNumbers(Map<String, dynamic> providerData) {
    final List<String> workingDayStrings =
        List<String>.from(providerData['workingDays'] ?? []);
    return _convertWeekdayStringsToInt(workingDayStrings);
  }

  static Set<int> _convertWeekdayStringsToInt(List<String> dayStrings) {
    const Map<String, int> dayMap = {
      'Mon': 1, 'Monday': 1,
      'Tue': 2, 'Tuesday': 2,
      'Wed': 3, 'Wednesday': 3,
      'Thu': 4, 'Thursday': 4,
      'Fri': 5, 'Friday': 5,
      'Sat': 6, 'Saturday': 6,
      'Sun': 7, 'Sunday': 7,
    };
    return dayStrings
        .where((day) => dayMap.containsKey(day))
        .map((day) => dayMap[day]!)
        .toSet();
  }

  // Service selection
  void selectService(int index) {
    final price = services[index]['price'] as int;
    emit(state.copyWith(
      selectedServiceIndex: index,
      totalPrice: price,
    ));
  }

  // Date selection
  void selectDate(DateTime date) {
    final isWorkingDay = _checkIfWorkingDay(date, providerData);
    emit(state.copyWith(
      selectedDate: date,
      isDateWorkingDay: isWorkingDay,
      selectedTimeIndex: -1,
      selectedTimeString: '',
      selectedTimeDateTime: null,
    ));
  }

  // Time slot selection
  void selectTimeSlot(int index, Map<String, dynamic> slot) {
    final timeDateTime = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      slot['hour'] as int,
      slot['minute'] as int,
    );
    emit(state.copyWith(
      selectedTimeIndex: index,
      selectedTimeString: slot['display'] as String,
      selectedTimeDateTime: timeDateTime,
    ));
  }

  // Generate time slots (pure function)
  List<Map<String, dynamic>> generateTimeSlots() {
    final workingHours = providerData['workingHours'] ??
        {'startHour': 8, 'startMinute': 0, 'endHour': 18, 'endMinute': 0};

    final startHour = workingHours['startHour'] ?? 9;
    final startMinute = workingHours['startMinute'] ?? 0;
    final endHour = workingHours['endHour'] ?? 17;
    final endMinute = workingHours['endMinute'] ?? 0;

    final slots = <Map<String, dynamic>>[];
    final now = DateTime.now();

    DateTime currentTime = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      startHour,
      startMinute,
    );

    final endTime = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      endHour,
      endMinute,
    );

    while (currentTime.isBefore(endTime)) {
      bool includeSlot = true;

      if (state.selectedDate.year == now.year &&
          state.selectedDate.month == now.month &&
          state.selectedDate.day == now.day) {
        if (!currentTime.isAfter(now)) {
          includeSlot = false;
        }
      }

      if (includeSlot) {
        final hour = currentTime.hour;
        final minute = currentTime.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final minuteStr = minute.toString().padLeft(2, '0');

        slots.add({
          'display': '$displayHour:$minuteStr $period',
          'hour': hour,
          'minute': minute,
          'period': period,
        });
      }

      currentTime = currentTime.add(const Duration(hours: 1));
    }

    return slots;
  }
}