import 'package:flutter/material.dart';

class RescheduleDialog extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onReschedule;
  const RescheduleDialog({Key? key, required this.booking, required this.onReschedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reschedule Appointment'),
      content: const Text('Would you like to choose a new date and time for this appointment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onReschedule();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Reschedule'),
        ),
      ],
    );
  }
}