import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:booking/presentaion/booking/widget/booking_summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:booking/domain/entities/booking_entity.dart';

class BookingBottomBar extends StatelessWidget {
  final Map<String, dynamic> user;
  const BookingBottomBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final formCubit = context.watch<BookingFormCubit>();
    final formState = formCubit.state;
    final totalPrice = formState.totalPrice;
    final isDateWorkingDay = formState.isDateWorkingDay;

    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '₵$totalPrice',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (formState.selectedServiceIndex == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a service')),
                  );
                  return;
                }
                if (!isDateWorkingDay) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shop closed on selected date'),
                    ),
                  );
                  return;
                }
                if (formState.selectedTimeIndex == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a time slot')),
                  );
                  return;
                }

                _showSummaryDialog(context, formCubit, formState, user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
        ],
      ),
    );
  }

  void _showSummaryDialog(
    BuildContext context,
    BookingFormCubit formCubit,
    BookingFormState formState,
    Map<String, dynamic> user,
    ) {
    final globalCubit = context.read<BookingCubit>();
    final providerData = formCubit.providerData;

    final selectedService = formCubit.services[formState.selectedServiceIndex!];
    final appointmentDateTime = formState.selectedTimeDateTime!;

    final timeSlot = TimeSlot(
      displayTime: formState.selectedTimeString,
      time: appointmentDateTime,
    );

    final booking = BookingEntity(
      id: '',
      serviceId: providerData['id'] ?? '',
      serviceName: providerData['name'] ?? 'Service',
      providerId: providerData['providerId'] ?? '',
      userId: user['id'],
      appointmentDate: appointmentDateTime,
      timeSlot: timeSlot,
      serviceOption: ServiceOption(
        price: selectedService['price'] ?? 0,
        title: selectedService['name'] ?? 'Service Option',
        durationMinutes: selectedService['duration'] ?? 60,
      ),
      totalAmount: formState.totalPrice,
      createdAt: DateTime.now(),
      userName: user['displayName'] ?? 'User',
      participants: [providerData['providerId'], user['id']],
      status: 'pending',
      latitude: providerData['latitude'] ?? 0.0,
      longitude: providerData['longitude'] ?? 0.0,
      workingDays: providerData['workingDays'],
      workingHours: providerData['workingHours'],
      services: formCubit.services,
      reminderSent: false,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BookingSummaryDialog(
        serviceName: selectedService['name'] ?? 'Service',
        date: formState.selectedDate,
        timeString: formState.selectedTimeString,
        totalPrice: formState.totalPrice,
        onConfirm: () {
          Navigator.pop(context); // close summary dialog
          globalCubit.createBooking(booking);
        },
      ),
    );
  }
}
