import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final VoidCallback onDelete;
  const DeleteDialog({Key? key, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Appointment'),
      content: const Text('Are you sure you want to delete this appointment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No, Keep It'),
        ),
        ElevatedButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Yes, Delete'),
        ),
      ],
    );
  }
}