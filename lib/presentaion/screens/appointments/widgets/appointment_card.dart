import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String salonName;
  final String userName;
  final String date;
  final String time;
  final String service;
  final String price;
  final String status;
  final String? cancellationReason;
  final int? rating;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReschedule;
  final VoidCallback? onDirections;
  final VoidCallback? onRebook;
  final VoidCallback? onDelete;
  final VoidCallback? onWriteReview;
  final VoidCallback? onBookAgain;
  final bool isProvider; // true if current user is the provider

  const AppointmentCard({
    super.key,
    required this.data,
    required this.salonName,
    required this.userName,
    required this.date,
    required this.time,
    required this.service,
    required this.price,
    required this.status,
    this.cancellationReason,
    this.rating,
    this.onCancel,
    this.onConfirm,
    this.onReschedule,
    this.onDirections,
    this.onRebook,
    this.onDelete,
    this.onWriteReview,
    this.onBookAgain,
    required this.isProvider,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    final bookingId = data['id'].substring(0, 6);
    final createdAt = data['createdAt']?.toDate() ?? DateTime.now();
    final formattedCreatedAt = DateFormat('MMMM d, yyyy').format(createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with Salon Info and Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salonName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isProvider)
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Booked by $userName',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusInfo.bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusInfo.icon,
                                      size: 14,
                                      color: statusInfo.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusInfo.text,
                                      style: TextStyle(
                                        color: statusInfo.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Booking ID: $bookingId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Created at: $formattedCreatedAt',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Appointment Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cut,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cancellation Reason (if cancelled)
                if (cancellationReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cancellationReason!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rating (if completed)
                if (rating != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Your Rating: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating! ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: _buildActionButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withOpacity(0.1),
            ),
            if (isProvider)
              Expanded(
                child: TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              Expanded(
                child: TextButton(
                  onPressed: onReschedule,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );

      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withOpacity(0.1),
            ),
            if (!isProvider)
              Expanded(
                child: TextButton(
                  onPressed: onDirections,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Directions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );

      case 'cancelled':
        return Row(
          children: [
            if (!isProvider)
              Expanded(
                child: TextButton(
                  onPressed: onRebook,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Rebook',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withOpacity(0.1),
            ),
            Expanded(
              child: TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Row(
          children: [
            if (!isProvider)
              Expanded(
                child: TextButton(
                  onPressed: onWriteReview,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Write Review',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withOpacity(0.1),
            ),
            if (!isProvider)
              Expanded(
                child: TextButton(
                  onPressed: onBookAgain,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Book Again',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );

      default:
        return Container();
    }
  }

  // Helper to get status colors and icons
  ({Color color, Color bgColor, String text, IconData icon}) _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return (
          color: Colors.orange,
          bgColor: Colors.orange.withOpacity(0.1),
          text: 'Pending',
          icon: Icons.schedule,
        );
      case 'confirmed':
        return (
          color: Colors.green,
          bgColor: Colors.green.withOpacity(0.1),
          text: 'Confirmed',
          icon: Icons.check_circle,
        );
      case 'cancelled':
        return (
          color: Colors.red,
          bgColor: Colors.red.withOpacity(0.1),
          text: 'Cancelled',
          icon: Icons.cancel,
        );
      case 'completed':
        return (
          color: Colors.blue,
          bgColor: Colors.blue.withOpacity(0.1),
          text: 'Completed',
          icon: Icons.done_all,
        );
      default:
        return (
          color: Colors.grey,
          bgColor: Colors.grey.withOpacity(0.1),
          text: 'Unknown',
          icon: Icons.help,
        );
    }
  }
}