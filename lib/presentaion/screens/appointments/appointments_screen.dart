import 'package:booking/core/utils/navigation_utils.dart';
import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:booking/presentaion/booking/re_book.dart';
import 'package:booking/presentaion/booking/update_booking.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/screens/appointments/widgets/appointment_card.dart';
import 'package:booking/presentaion/screens/appointments/widgets/cancel_dialog.dart';
import 'package:booking/presentaion/screens/appointments/widgets/confirm_dialog.dart';
import 'package:booking/presentaion/screens/appointments/widgets/delete_dialog.dart';
import 'package:booking/presentaion/screens/appointments/widgets/reschedule_dialog.dart';
import 'package:booking/presentaion/screens/appointments/widgets/review_dialog.dart';
import 'package:booking/presentaion/screens/appointments/widgets/stat_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AppointmentsScreen({super.key, required this.user});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingDirections = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _fetchBookings() {
    context.read<BookingCubit>().listenToUserBookings(widget.user['id']);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) =>
      DateFormat('MMMM d, yyyy').format(dateTime);

  Future<void> _handleDirections(double lat, double lng) async {
    setState(() => _isLoadingDirections = true);
    try {
      await NavigationUtils.openDirectionsWithExplicitStart(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDirections = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is BookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const LoadingScreen();
          } else if (state is BookingLoaded) {
            final bookings = state.bookings;
            final pending = bookings
                .where((b) => b['status'] == 'pending')
                .toList();
            final confirmed = bookings
                .where((b) => b['status'] == 'confirmed')
                .toList();
            final cancelled = bookings
                .where((b) => b['status'] == 'cancelled')
                .toList();
            final completed = bookings
                .where((b) => b['status'] == 'completed')
                .toList();

            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(
                      pending.length,
                      confirmed.length,
                      cancelled.length,
                    ),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabContent(pending, 'pending'),
                          _buildTabContent(confirmed, 'confirmed'),
                          _buildTabContent(cancelled, 'cancelled'),
                          _buildTabContent(completed, 'completed'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isLoadingDirections)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
              ],
            );
          } else if (state is BookingError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(int pending, int confirmed, int cancelled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Appointments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatBadge(count: pending, label: 'Pending'),
              StatBadge(count: confirmed, label: 'Confirmed'),
              StatBadge(count: cancelled, label: 'Cancelled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        isScrollable: false,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Confirmed'),
          Tab(text: 'Cancelled'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTabContent(List bookings, String status) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(status), size: 48, color: Colors.grey),
            Text(
              _getEmptyMessage(status),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppointmentCard(
            data: booking,
            salonName: booking['serviceName'] ?? 'Unknown Service',
            userName: booking['userName'] ?? 'Unknown User',
            date: _formatDate(booking['appointmentDate'].toDate()),
            time: booking['timeSlot']['displayTime'] ?? 'Unknown Time',
            service: booking['serviceOption']['title'] ?? 'Unknown Service',
            price: '₵${booking['serviceOption']['price']}',
            status: booking['status'] ?? status,
            cancellationReason: booking['cancelReason'],
            rating: booking['rating'],
            isProvider: widget.user['id'] == booking['providerId'],
            onCancel: () => _showCancelDialog(booking),
            onConfirm: () => _showConfirmDialog(booking),
            onReschedule: () => _showRescheduleDialog(booking),
            onDirections: () => _handleDirections(
              booking['latitude'] ?? 0.0,
              booking['longitude'] ?? 0.0,
            ),
            onRebook: () => _navigateToRebook(booking),
            onDelete: () => _showDeleteDialog(booking),
            onWriteReview: () => _showReviewDialog(booking),
            onBookAgain: () => _navigateToRebook(booking),
          ),
        );
      },
    );
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.done_all_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'No pending appointments yet.';
      case 'confirmed':
        return 'No confirmed appointments yet.';
      case 'cancelled':
        return 'No cancelled appointments yet.';
      case 'completed':
        return 'No completed appointments yet.';
      default:
        return 'No appointments.';
    }
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => CancelDialog(
        booking: booking,
        userId: widget.user['id'],
        onCancel: (reason) {
          final targetId = widget.user['id'] == booking['providerId']
              ? booking['userId']
              : booking['providerId'];

          context.read<BookingCubit>().cancelBooking(
            booking['id'],
            reason,
            targetId,
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => DeleteDialog(
        onDelete: () {
          context.read<BookingCubit>().deleteBooking(booking['id']);
        },
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => RescheduleDialog(
        booking: booking,
        onReschedule: () {
          // Navigate to update booking screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UpdateBookingScreen(data: booking), // Adjust import
            ),
          );
        },
      ),
    );
  }

  void _showConfirmDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        onConfirm: () {
          context.read<BookingCubit>().confirmBooking(
            booking['id'],
            booking['userId'],
          );
        },
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => ReviewDialog(
        booking: booking,
        userId: widget.user['id'],
        userName: widget.user['displayName'] ?? 'User',
      ),
    );
  }

  void _navigateToRebook(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReBook(data: booking), // Adjust import
      ),
    );
  }
}
