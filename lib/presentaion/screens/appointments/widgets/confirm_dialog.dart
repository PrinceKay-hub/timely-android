import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const ConfirmDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirm Appointment'),
      content: const Text('Would you like to confirm this appointment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}