import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoryStep extends StatelessWidget {
  final ServiceEntity service;
  static const String _cacheKey = 'categories';

  const CategoryStep({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ServiceRegistrationCubit>();
    final categories = Hive.box('myBox').get(_cacheKey) as List? ?? [];
    if (service.category.isNotEmpty) {
      cubit.updateServiceCategory(service.category);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.category,
              color: Theme.of(context).colorScheme.primary, size: 60),
          const SizedBox(height: 20),
          const Text('Select Category',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Choose the category that best describes your business',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = service.category == cat['name'];
              return GestureDetector(
                onTap: () =>
                    cubit.updateServiceCategory(cat['name'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: cat['icon'] as String,
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                        memCacheWidth: 150,
                        placeholder: (context, url) => Icon(
                          Icons.image_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}