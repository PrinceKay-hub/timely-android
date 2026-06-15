import 'package:flutter/material.dart';

class WorkingHoursDisplay extends StatelessWidget {
  final Map<String, dynamic> service;

  const WorkingHoursDisplay({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkingDaysDisplay(context),
        const SizedBox(height: 8),
        _buildWorkingHoursDisplay(context),
      ],
    );
  }

  Widget _buildWorkingDaysDisplay(BuildContext context) {
    final days = service['workingDays'];
    
    if (days.isEmpty) {
      return const Text(
        'No working days specified',
        style: TextStyle(color: Colors.grey),
      );
    }

    // Sort days in week order
    final dayOrder = {
      'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7
    };
    
    days.sort((a, b) => (dayOrder[a] ?? 8).compareTo(dayOrder[b] ?? 8));
    
    // Check for common patterns
    if (days.length == 7) {
      return const Text(
        'Open everyday',
        style: TextStyle(fontSize: 14),
      );
    }
    
    if (days.length == 5 && 
        days.contains('Mon') && 
        days.contains('Tue') && 
        days.contains('Wed') && 
        days.contains('Thu') && 
        days.contains('Fri')) {
      return const Text(
        'Weekdays only',
        style: TextStyle(fontSize: 14),
      );
    }
    
    if (days.length == 2 && 
        days.contains('Sat') && 
        days.contains('Sun')) {
      return const Text(
        'Weekends only',
        style: TextStyle(fontSize: 14),
      );
    }
    
    // Format as ranges or list
    if (_isConsecutive(days)) {
      return Text(
        '${days.first} - ${days.last}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,),
      );
    }
    
    return Text(
      days.join(', '),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,),
    );
  }

  Widget _buildWorkingHoursDisplay(BuildContext context) {
    final hours = service['workingHours'];
    
    String formatTime(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12;
      final displayHour = hour12 == 0 ? 12 : hour12;
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
    
    final startTime = formatTime(hours['startHour'], hours['startMinute']);
    final endTime = formatTime(hours['endHour'], hours['endMinute']);
    
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          '$startTime - $endTime',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  bool _isConsecutive(List days) {
    if (days.length < 2) return false;
    
    final dayOrder = {
      'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7
    };
    
    for (int i = 1; i < days.length; i++) {
      final currentDayIndex = dayOrder[days[i]];
      final previousDayIndex = dayOrder[days[i - 1]];
      
      if (currentDayIndex == null || previousDayIndex == null) {
        return false;
      }
      
      if (currentDayIndex != previousDayIndex + 1) {
        return false;
      }
    }
    
    return true;
  }
}