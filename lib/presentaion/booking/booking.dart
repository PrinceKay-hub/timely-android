
import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:booking/presentaion/booking/widget/booking_bottom_bar.dart';
import 'package:booking/presentaion/booking/widget/booking_form.dart';
import 'package:booking/presentaion/booking/widget/booking_header.dart';
import 'package:booking/presentaion/common/pages/error_screen.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/provider/cubit/service_detail/service_detail_cubit.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingScreen extends StatefulWidget {
  final String id;
  const BookingScreen({super.key, required this.id});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final service = context.read<ServiceDetailCubit>();
  late final userCubit = context.read<UserCubit>();

  @override
  void initState() {
    service.getServiceById(widget.id);
    userCubit.loadUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Get the global BookingCubit (must be provided above)
    final globalBookingCubit = context.read<BookingCubit>();

    return BlocBuilder<ServiceDetailCubit, ServiceDetailState>(
      builder: (context, state) {
        if (state is ServiceDetailLoading) {
          return LoadingScreen();
        } else if (state is ServiceDetailError) {
          return ErrorScreen(error: state.message);
        } else if (state is ServiceDetailLoaded) {
          final serviceData = state.serviceData;

          return BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              if (state is UserLoaded) {
                final user = state.user;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => BookingFormCubit(
                        providerData: serviceData,
                        services: List<Map<String, dynamic>>.from(
                          serviceData['services'] ?? [],
                        ),
                      ),
                    ),
                    BlocProvider<BookingCubit>.value(value: globalBookingCubit),
                  ],
                  child: BookingScreenView(user: user, id: widget.id),
                );
              }
              return SizedBox.shrink();
            },
          );
        } else {
          return ErrorScreen(error: 'Unexpected state: $state');
        }
      },
    );
  }
}

class BookingScreenView extends StatelessWidget {
  final Map<String, dynamic> user;
  final String id;
  const BookingScreenView({super.key, required this.user, required this.id});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to global booking cubit for success/error
        BlocListener<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingSuccess) {
              final userCubit = context.read<UserCubit>();

              _showSuccessDialog(context, state.message);
              userCubit.loadUser();
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
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Scaffold(
                  body: Column(
                    children: [
                      BookingHeader(serviceId: id),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: BookingForm(user: user),
                        ),
                      ),
                      SafeArea(child: BookingBottomBar(user: user)),
                    ],
                  ),
                ),
                if (state is BookingLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
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
                  Navigator.pop(context);
                  Navigator.pop(context);
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
