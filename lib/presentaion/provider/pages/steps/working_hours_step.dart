import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkingHoursStep extends StatefulWidget {
  final ServiceEntity service;

  const WorkingHoursStep({super.key, required this.service});

  @override
  State<WorkingHoursStep> createState() => _WorkingHoursStepState();
}

class _WorkingHoursStepState extends State<WorkingHoursStep> {
  static const List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  // TimeOfDay is local-only: a UI intermediary for the time picker.
  // Initialized from widget.service on first build, then owned locally.
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _initialised = false;

  @override
  void didUpdateWidget(WorkingHoursStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If working hours change externally (e.g. chat AI fills them in),
    // reset local times so the UI reflects the new values.
    final oldWh = oldWidget.service.workingHours;
    final newWh = widget.service.workingHours;
    if (oldWh != newWh) {
      _startTime = TimeOfDay(hour: newWh.startHour, minute: newWh.startMinute);
      _endTime = TimeOfDay(hour: newWh.endHour, minute: newWh.endMinute);
    }
  }

  void _initFromService() {
    if (_initialised) return;
    final wh = widget.service.workingHours;
    _startTime = TimeOfDay(hour: wh.startHour, minute: wh.startMinute);
    _endTime = TimeOfDay(hour: wh.endHour, minute: wh.endMinute);
    _initialised = true;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final cubit = context.read<ServiceRegistrationCubit>();
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));

    final time = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodColor: Theme.of(context).primaryColor,
              dayPeriodTextColor:
                  Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          child: child,
        );
      },
    );

    if (time == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }
    });

    final start = isStart ? time : _startTime;
    final end = isStart ? _endTime : time;
    if (start != null && end != null) {
      cubit.updateWorkingHours(WorkingHours(
        startHour: start.hour,
        startMinute: start.minute,
        endHour: end.hour,
        endMinute: end.minute,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromService();

    final cubit = context.read<ServiceRegistrationCubit>();
    final workingDays = widget.service.workingDays;

    final startMin =
        (_startTime?.hour ?? 0) * 60 + (_startTime?.minute ?? 0);
    final endMin = (_endTime?.hour ?? 0) * 60 + (_endTime?.minute ?? 0);
    final hasInvalidRange =
        _startTime != null && _endTime != null && endMin <= startMin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.access_time,
              color: Theme.of(context).colorScheme.primary, size: 60),
          const SizedBox(height: 20),
          const Text('Working Hours',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'When are you available for appointments?',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Working Days ──────────────────────────────────
                const Text('Working Days',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((day) {
                    final isSelected = workingDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        final updated = List<String>.from(workingDays);
                        if (isSelected) {
                          updated.remove(day);
                        } else {
                          updated.add(day);
                        }
                        cubit.updateWorkingDays(updated);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // ── Operating Hours ───────────────────────────────
                const Text('Operating Hours',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                _startTime?.format(context) ?? '08:00 AM',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, color: Colors.grey),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                _endTime?.format(context) ?? '06:00 PM',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasInvalidRange) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'End time must be after start time',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}