import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimeSlots extends StatelessWidget {
  const TimeSlots({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookingFormCubit>();
    final state = cubit.state;
    final slots = cubit.generateTimeSlots();
    final selectedIndex = state.selectedTimeIndex;

    return Wrap(
      key: ValueKey(state.selectedDate),
      spacing: 12,
      runSpacing: 12,
      children: List.generate(slots.length, (index) {
        final slot = slots[index];
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => cubit.selectTimeSlot(index, slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Text(
              slot['display'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}