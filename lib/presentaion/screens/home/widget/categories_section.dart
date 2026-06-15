// lib/presentation/home/widgets/categories_section.dart
import 'package:booking/presentaion/screens/home/cubit/home_cubit.dart';
import 'package:booking/presentaion/screens/home/widget/categorySearch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesSection extends StatelessWidget {
  final Map<String, dynamic> user;
  const CategoriesSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories ||
          previous.categoriesError != current.categoriesError,
      builder: (context, state) {
        if (state.categoriesError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Failed to load categories: ${state.categoriesError}'),
            ),
          );
        }
        if (state.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Categorysearch(
                              category: category['name'],
                              user: user,
                            ),
                          ),
                        );
                      },
                      child: _buildServiceIcon(context, category['icon'], category['name']),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceIcon(BuildContext context, String icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: CachedNetworkImage(
              imageUrl: icon,
              height: 50,
              width: 50,
              fit: BoxFit.contain,
              memCacheWidth: 150,
              placeholder: (context, url) => Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.secondary,),
              ) 
            
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}