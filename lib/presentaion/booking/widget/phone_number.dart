import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class InputPhoneNumber extends StatelessWidget {
  const InputPhoneNumber({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingFormCubit>();
    InputDecoration _fieldDecoration({
      required String hint,
      required IconData icon,
      String? label,
    }) {
      final primary = Theme.of(context).colorScheme.primary;
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text('Add contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        IntlPhoneField(
          keyboardType: TextInputType.phone,
          autofocus: false,
          decoration: _fieldDecoration(
            hint: '24 123 4567',
            icon: Icons.phone_outlined,
            label: '244 123456',
          ),
          initialCountryCode: 'GH',
          onChanged: (phone) => cubit.selectPhone(phone.completeNumber),
        ),
        const SizedBox(height: 6),
        Text(
          'This is will be collected once.',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ],
    );
  }
}
