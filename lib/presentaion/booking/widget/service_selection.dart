import 'package:booking/presentaion/booking/cubit/booking_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServiceSelection extends StatelessWidget {
  const ServiceSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingFormCubit>();
    final services = cubit.services;
    final selectedIndex = context.select((BookingFormCubit c) => c.state.selectedServiceIndex);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        final service = services[index];

        return GestureDetector(
          onTap: () => cubit.selectService(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${service['duration']?.toString() ?? '0'} mins',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₵${service['price']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}