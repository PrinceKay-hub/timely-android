import 'package:booking/core/services/send_notification.dart';
import 'package:booking/domain/entities/booking_entity.dart';
import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UpdateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const UpdateBookingScreen({super.key, required this.data});

  @override
  State<UpdateBookingScreen> createState() => _UpdateBookingScreenState();
}

class _UpdateBookingScreenState extends State<UpdateBookingScreen> {
 
  int _selectedTimeIndex = -1;
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeString = '';
  DateTime? _selectedTimeDateTime;
  int totalPrice = 0;

  @override
  void initState() {
    super.initState();

    // Normalize today (remove time part)
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    // Get working days from provider data
    final List<String> workingDayStrings =
        List<String>.from(widget.data['workingDays'] ?? []);
    final Set<int> workingDayNumbers =
        _convertWeekdayStringsToInt(workingDayStrings);

    // If today is a working day, set it as selected
    if (workingDayNumbers.contains(todayDateOnly.weekday)) {
      _selectedDate = todayDateOnly;
    }
    
  }

  // Computed property: whether the currently selected date is a working day
  bool get _isSelectedDateWorkingDay {
    final List<String> workingDayStrings =
        List<String>.from(widget.data['workingDays'] ?? []);
    final Set<int> workingDayNumbers =
        _convertWeekdayStringsToInt(workingDayStrings);
    return workingDayNumbers.contains(_selectedDate.weekday);
  }



  // user notification for reschule
  void sendnotification(String title, String userIDs) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userIDs).get();

    String token = snapshot['fcmToken'];
    
    SendNotificationService().sendNotificationViaCloudFunction(
      title: title,
      body: 'Open app for more details', 
      deviceToken: token,
    );
  }

   @override
  Widget build(BuildContext context) {
    
    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          _showSuccessDialog(context, state.message);
          sendnotification('Appointment Rescheduled', widget.data['providerId']);
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Text(
                          'Reschedule Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child:  Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Booking Form
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBookingForms(context, state),
                  ),
                ),
              ),

              // Bottom Booking Summary
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        
                          if (!_isSelectedDateWorkingDay) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Shop closed on selected date'),
                              ),
                            );
                            return;
                          }
                                  
                        _showBookingSummary(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'View Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingForms(BuildContext context, BookingState state) {
    if (state is BookingLoading) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Date
          const Text(
            'Select Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCalendar(),
          const SizedBox(height: 24),

          // Select Time
          const Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTimeSlots(),
          const SizedBox(height: 20),
        ],
      );
    }
  }
 
  Widget _buildCalendar() {
    final now = DateTime.now();
    final currentMonth = DateTime(_selectedDate.year, _selectedDate.month);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                  });
                },
              ),
              Text(
                _getMonthYear(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
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
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Grid
          ..._buildCalendarWeeks(currentMonth, now),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarWeeks(DateTime month, DateTime today) {
    // Convert string working days to weekday integers
    final List<String> workingDayStrings = List<String>.from(
      widget.data['workingDays'] ?? [],
    );
    final Set<int> workingDayNumbers = _convertWeekdayStringsToInt(
      workingDayStrings,
    );

    List<Widget> weeks = [];

    // Get first day of month and calculate starting position
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Adjust for Monday as first day of week (1 = Monday, 7 = Sunday)
    int startingWeekday = firstDayOfMonth.weekday - 1;
    if (startingWeekday == -1) startingWeekday = 6; // Handle Sunday

    int currentDay = 1;
    int weeksCount = ((lastDayOfMonth.day + startingWeekday) / 7).ceil();

    for (int week = 0; week < weeksCount; week++) {
      List<Widget> dayWidgets = [];

      for (int weekday = 0; weekday < 7; weekday++) {
        if ((week == 0 && weekday < startingWeekday) ||
            currentDay > lastDayOfMonth.day) {
          // Empty cell
          dayWidgets.add(Expanded(child: Container()));
        } else {
          // Day cell
          final date = DateTime(month.year, month.month, currentDay);
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected =
              date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isPast = date.isBefore(
            DateTime(today.year, today.month, today.day),
          );

          // FIXED: Use the converted integer set
          final isWorkingDay = workingDayNumbers.contains(date.weekday);

          dayWidgets.add(
            Expanded(
              child: _buildCalendarDay(
                currentDay,
                isSelected,
                isToday,
                isPast,
                date,
                isWorkingDay,
              ),
            ),
          );
          currentDay++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayWidgets,
          ),
        ),
      );
    }

    return weeks;
  }

  // Helper function to convert weekday strings to integers
  Set<int> _convertWeekdayStringsToInt(List<String> dayStrings) {
    final Map<String, int> dayMap = {
      'Mon': 1,
      'Monday': 1,
      'Tue': 2,
      'Tuesday': 2,
      'Wed': 3,
      'Wednesday': 3,
      'Thu': 4,
      'Thursday': 4,
      'Fri': 5,
      'Friday': 5,
      'Sat': 6,
      'Saturday': 6,
      'Sun': 7,
      'Sunday': 7,
    };

    return dayStrings
        .where((day) => dayMap.containsKey(day))
        .map((day) => dayMap[day]!)
        .toSet();
  }

  Widget _buildCalendarDay(
    int day,
    bool isSelected,
    bool isToday,
    bool isPast,
    DateTime date,
    bool isWorkingDay,
  ) {
    final isDisabled = isPast || !isWorkingDay;

    return Tooltip(
      message: isWorkingDay ? 'Available for booking' : 'Shop is closed',
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _selectedDate = date;
                });
              },
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
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (!isWorkingDay && !isPast)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    final workingHours =
        widget.data['workingHours'] ??
        {'startHour': 8, 'startMinute': 0, 'endHour': 18, 'endMinute': 0};

    final timeSlots = _generateTimeSlots(workingHours);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: timeSlots.asMap().entries.map((entry) {
        final index = entry.key;
        final timeSlot = entry.value;
        return _buildTimeSlot(index, timeSlot);
      }).toList(),
    );
  }

  Widget _buildTimeSlot(int index, Map<String, dynamic> timeSlot) {
    final isSelected = _selectedTimeIndex == index;
    final displayTime = timeSlot['display'] as String;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeIndex = index;
          _selectedTimeString = displayTime;
          // Store the hour and minute for later use
          _selectedTimeDateTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            timeSlot['hour'] as int,
            timeSlot['minute'] as int,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          displayTime,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateTimeSlots(Map<String, dynamic> workingHours) {
  final startHour = workingHours['startHour'] ?? 9;
  final startMinute = workingHours['startMinute'] ?? 0;
  final endHour = workingHours['endHour'] ?? 17;
  final endMinute = workingHours['endMinute'] ?? 0;

  final slots = <Map<String, dynamic>>[];
  final now = DateTime.now();

  // Build the start of working hours on the SELECTED date
  DateTime currentTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    startHour,
    startMinute,
  );

  final endTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    endHour,
    endMinute,
  );

  while (currentTime.isBefore(endTime)) {
    bool includeSlot = true;

    // If the selected date is today, filter out past times
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      if (!currentTime.isAfter(now)) {
        includeSlot = false; // slot is in the past or exactly now
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

    // Move to next hour
    currentTime = currentTime.add(const Duration(hours: 1));
  }

  return slots;
}

  void _showBookingSummary(BuildContext context) {
    final cubit = context.read<BookingCubit>();

    // Validate that a time slot is selected
    if (_selectedTimeIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          height: 250,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              const Text(
                'Reschedule Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date:'),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time:'),
                    Text(
                      _selectedTimeString,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedTimeDateTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a time slot'),
                        ),
                      );
                      return;
                    }

                    // Combine selected date with selected time
                    final appointmentDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTimeDateTime!.hour,
                      _selectedTimeDateTime!.minute,
                    );

                    final timeSlot = TimeSlot(
                      displayTime: _selectedTimeString,
                      time: appointmentDateTime,
                    );

                    cubit.updateBooking(widget.data['id'], appointmentDateTime, timeSlot);
                    Navigator.pop(context); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child:  Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reschedule Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}