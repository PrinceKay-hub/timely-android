import 'package:flutter/material.dart';

class CancelDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String userId;
  final Function(String) onCancel;

  const CancelDialog({
    Key? key,
    required this.booking,
    required this.userId,
    required this.onCancel,
  }) : super(key: key);

  @override
  _CancelDialogState createState() => _CancelDialogState();
}

class _CancelDialogState extends State<CancelDialog> {
  String? _selectedReason;

  final List<String> _clientReasons = [
    'Schedule conflict',
    'Changed my mind',
    'There is an emergency',
    'Found another provider',
    'Other',
  ];

  final List<String> _providerReasons = [
    'Schedule conflict',
    'Unforeseen Emergency',
    'Overbooking',
    'Stylist not available',
    'Other',
  ];

  List<String> get _reasons =>
      widget.userId == widget.booking['providerId'] ? _providerReasons : _clientReasons;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cancel Appointment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please tell us why you are cancelling:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) => setState(() => _selectedReason = value),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No, Keep It'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  widget.onCancel(_selectedReason!);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.withOpacity(0.4),
          ),
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}