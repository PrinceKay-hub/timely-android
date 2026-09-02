import 'package:flutter/material.dart';

class OpenStatusBadge extends StatelessWidget {
  final Map<String, dynamic> service;

  const OpenStatusBadge({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOpenStatusBadge(context),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Open/Closed status ────────────────────────────────────────────────

  Widget _buildOpenStatusBadge(BuildContext context) {
    final status = _computeOpenStatus();

    final Color color = status.isOpen ? Colors.green : Colors.red;
    final Color bg = status.isOpen
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                status.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (status.detail != null) ...[
          const SizedBox(width: 8),
          Text(
            status.detail!,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  _OpenStatus _computeOpenStatus() {
    final days = List<String>.from(service['workingDays'] ?? const []);
    final hours = service['workingHours'];

    if (days.isEmpty || hours == null) {
      return const _OpenStatus(isOpen: false, detail: null);
    }

    const dayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    final startHour = hours['startHour'] as int;
    final startMinute = hours['startMinute'] as int;
    final endHour = hours['endHour'] as int;
    final endMinute = hours['endMinute'] as int;

    final startMinutes = startHour * 60 + startMinute;
    var endMinutes = endHour * 60 + endMinute;
    final overnight = endMinutes <= startMinutes; // e.g. 18:00 -> 02:00
    if (overnight) endMinutes += 24 * 60;

    bool worksOn(int weekdayIndex) => days.contains(dayAbbrev[weekdayIndex]);

    // weekday: 1 = Mon ... 7 = Sun -> convert to 0-based index
    final todayIndex = now.weekday - 1;
    final nowMinutes = now.hour * 60 + now.minute;

    bool isOpen = false;
    int? minutesUntilClose;
    int? minutesUntilOpen; // set only when the shop opens LATER TODAY

    // Check today's shift, and yesterday's shift if it's an overnight
    // shift that spills into today.
    if (worksOn(todayIndex)) {
      if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
        isOpen = true;
        minutesUntilClose = endMinutes - nowMinutes;
      } else if (nowMinutes < startMinutes) {
        minutesUntilOpen = startMinutes - nowMinutes;
      }
    }

    if (!isOpen && overnight) {
      final yesterdayIndex = (todayIndex - 1 + 7) % 7;
      if (worksOn(yesterdayIndex)) {
        final nowMinutesExtended = nowMinutes + 24 * 60;
        if (nowMinutesExtended >= startMinutes + 24 * 60 == false &&
            nowMinutes < (endMinutes - 24 * 60)) {
          isOpen = true;
          minutesUntilClose = (endMinutes - 24 * 60) - nowMinutes;
        }
      }
    }

    String? detail;
    if (isOpen && minutesUntilClose != null) {
      if (minutesUntilClose <= 60) {
        detail = 'Closes in ${minutesUntilClose}m';
      } else {
        detail = 'Closes at ${_formatTime(endHour, endMinute)}';
      }
    } else if (!isOpen) {
      if (minutesUntilOpen != null) {
        detail = minutesUntilOpen <= 60
            ? 'Opens in ${minutesUntilOpen}m'
            : 'Opens today at ${_formatTime(startHour, startMinute)}';
      } else {
        final nextDay = _nextOpenDayLabel(days, todayIndex);
        detail = nextDay != null
            ? 'Opens $nextDay ${_formatTime(startHour, startMinute)}'
            : null;
      }
    }

    return _OpenStatus(isOpen: isOpen, detail: detail);
  }

  String? _nextOpenDayLabel(List<String> days, int todayIndex) {
    const dayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayFull = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    for (int i = 1; i <= 7; i++) {
      final idx = (todayIndex + i) % 7;
      if (days.contains(dayAbbrev[idx])) {
        return i == 1 ? 'tomorrow' : dayFull[idx];
      }
    }
    return null;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12;
    final displayHour = hour12 == 0 ? 12 : hour12;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }


}

class _OpenStatus {
  final bool isOpen;
  final String? detail;

  const _OpenStatus({required this.isOpen, this.detail});
}