import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:booking/presentaion/booking/widget/booking_bottom_bar.dart';
import 'package:booking/presentaion/booking/widget/booking_form.dart';
import 'package:booking/presentaion/booking/widget/booking_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> user;

  const BookingScreen({super.key, required this.data, required this.user});

  @override
  Widget build(BuildContext context) {
    // Get the global BookingCubit (must be provided above)
    final globalBookingCubit = context.read<BookingCubit>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BookingFormCubit(
            providerData: data,
            services: List<Map<String, dynamic>>.from(data['services'] ?? []),
          ),
        ),
        BlocProvider<BookingCubit>.value(value: globalBookingCubit),
      ],
      child: BookingScreenView(user: user),
    );
  }
}

class BookingScreenView extends StatelessWidget {
  final Map<String, dynamic> user;
  const BookingScreenView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to global booking cubit for success/error
        BlocListener<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingSuccess) {

              _showSuccessDialog(context, state.message);

            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
                body: Column(
                  children: [
                    const BookingHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const BookingForm(),
                      ),
                    ),
                    BookingBottomBar(user: user),
                  ],
                ),
              ),
              if (state is BookingLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close booking screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
