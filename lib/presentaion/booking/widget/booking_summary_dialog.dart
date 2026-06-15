import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingSummaryDialog extends StatelessWidget {
  final String serviceName;
  final DateTime date;
  final String timeString;
  final int totalPrice;
  final VoidCallback onConfirm;

  const BookingSummaryDialog({
    super.key,
    required this.serviceName,
    required this.date,
    required this.timeString,
    required this.totalPrice,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            _buildRow('Service:', serviceName),
            _buildRow('Date:', DateFormat('MMMM d, yyyy').format(date)),
            _buildRow('Time:', timeString),
            const SizedBox(height: 16),
            _buildRow('Total Amount', '₵$totalPrice', isTotal: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onConfirm();
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? const TextStyle(fontSize: 16) : null),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 20 : 15,
              color: isTotal ? const Color(0xFF8B5CF6) : null,
            ),
          ),
        ],
      ),
    );
  }
}