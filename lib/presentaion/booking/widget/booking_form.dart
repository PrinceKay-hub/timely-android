import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:booking/presentaion/booking/widget/calendar_view.dart';
import 'package:booking/presentaion/booking/widget/phone_number.dart';
import 'package:booking/presentaion/booking/widget/service_selection.dart';
import 'package:booking/presentaion/booking/widget/time_slots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingForm extends StatelessWidget {
  final Map<String, dynamic> user;
  const BookingForm({super.key, required this.user});

  @override
  Widget build(BuildContext context) {


    return BlocBuilder<BookingFormCubit, BookingFormState>(
      builder: (context, state) {
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            Text('Select Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ServiceSelection(),
            SizedBox(height: 24),
            Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            CalendarView(),
            SizedBox(height: 24),
            Text('Select Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            TimeSlots(),
            if (user['phone'] == null)
            InputPhoneNumber(),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }
}