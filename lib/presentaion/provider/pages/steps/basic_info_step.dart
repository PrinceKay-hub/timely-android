import 'package:booking/core/services/registration_chat_service.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/pages/registration_chat_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BasicInfoStep extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback onOpenChat;
  static const String _cacheKey = 'categories';

  const BasicInfoStep({
    super.key,
    required this.service,
    required this.onOpenChat,
  });

  static Future<void> launchChat(
    BuildContext context,
    ServiceRegistrationCubit cubit,
  ) async {
    final box = Hive.box('myBox');
    final rawCategories = box.get(_cacheKey) as List? ?? [];
    final categoryNames = rawCategories
        .map((c) => (c is Map ? c['name'] : c)?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    if (categoryNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Categories are still loading, please try again in a moment.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push<ExtractedRegistration>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationChatScreen(categoryNames: categoryNames),
      ),
    );

    if (result == null) return;

    cubit.updateServiceName(result.name);
    cubit.updateServiceCategory(result.category);
    cubit.updateServiceDescription(result.description);
    cubit.updateServices(result.services);
    cubit.updateWorkingDays(result.workingDays);
    cubit.updateAmenities(result.amenities);
    cubit.updateWorkingHours(
      WorkingHours(
        startHour: result.workingHours['startHour'] ?? 9,
        startMinute: result.workingHours['startMinute'] ?? 0,
        endHour: result.workingHours['endHour'] ?? 17,
        endMinute: result.workingHours['endMinute'] ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ServiceRegistrationCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.store,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's start with the basics. What's your business name?",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (service.name.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: onOpenChat,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Prefer to just chat? Set up your whole profile by answering a few quick questions',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                // key ensures the field resets when name is cleared externally
                // (e.g. resetForm), but preserves typing state otherwise.
                TextFormField(
                  key: ValueKey(service.name.isEmpty ? 'empty' : 'filled'),
                  initialValue: service.name,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: cubit.updateServiceName,
                  decoration: InputDecoration(
                    hintText: 'e.g., Classic Cuts Barber Shop',
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
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Number of Staff',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: service.workers > 1
                          ? () =>
                                cubit.updateServiceWorkers(service.workers - 1)
                          : null,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${service.workers} ${service.workers == 1 ? 'Staff Member' : 'Staff Members'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          cubit.updateServiceWorkers(service.workers + 1),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
