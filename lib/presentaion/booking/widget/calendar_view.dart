import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingFormCubit>();
    final selectedDate = context.select((BookingFormCubit c) => c.state.selectedDate);
    final providerData = cubit.providerData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final newDate = DateTime(selectedDate.year, selectedDate.month - 1);
                  cubit.selectDate(newDate);
                },
              ),
              Text(
                _getMonthYear(selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final newDate = DateTime(selectedDate.year, selectedDate.month + 1);
                  cubit.selectDate(newDate);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          ..._buildWeeks(context, selectedDate, providerData),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context, DateTime month, Map<String, dynamic> providerData) {
    final today = DateTime.now();
    final workingDayNumbers = _getWorkingDayNumbers(providerData);
    final selectedDate = context.select((BookingFormCubit c) => c.state.selectedDate);

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    int startingWeekday = firstDayOfMonth.weekday - 1;
    if (startingWeekday == -1) startingWeekday = 6;

    int currentDay = 1;
    int weeksCount = ((lastDayOfMonth.day + startingWeekday) / 7).ceil();

    List<Widget> weeks = [];

    for (int week = 0; week < weeksCount; week++) {
      List<Widget> dayWidgets = [];

      for (int weekday = 0; weekday < 7; weekday++) {
        if ((week == 0 && weekday < startingWeekday) || currentDay > lastDayOfMonth.day) {
          dayWidgets.add(Expanded(child: Container()));
        } else {
          final date = DateTime(month.year, month.month, currentDay);
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
          final isWorkingDay = workingDayNumbers.contains(date.weekday);

          dayWidgets.add(
            Expanded(
              child: _buildDayCell(
                context,
                day: currentDay,
                isSelected: isSelected,
                isToday: isToday,
                isPast: isPast,
                isWorkingDay: isWorkingDay,
                onTap: isPast || !isWorkingDay ? null : () => _selectDate(context, date),
              ),
            ),
          );
          currentDay++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: dayWidgets),
        ),
      );
    }

    return weeks;
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int day,
    required bool isSelected,
    required bool isToday,
    required bool isPast,
    required bool isWorkingDay,
    VoidCallback? onTap,
  }) {
    final isDisabled = isPast || !isWorkingDay;

    return Tooltip(
      message: isWorkingDay ? 'Available for booking' : 'Shop is closed',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isToday
                ? const Color(0xFFEDE9FE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected
                ? Border.all(color: const Color(0xFF8B5CF6), width: 1)
                : null,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : isSelected
                        ? Colors.white
                        : isToday
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (!isWorkingDay && !isPast)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: CircleAvatar(radius: 3, backgroundColor: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectDate(BuildContext context, DateTime date) {
    context.read<BookingFormCubit>().selectDate(date);
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Set<int> _getWorkingDayNumbers(Map<String, dynamic> providerData) {
    final List<String> workingDayStrings =
        List<String>.from(providerData['workingDays'] ?? []);
    return _convertWeekdayStringsToInt(workingDayStrings);
  }

  Set<int> _convertWeekdayStringsToInt(List<String> dayStrings) {
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
}