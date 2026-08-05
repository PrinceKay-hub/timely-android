import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/pages/widgets/service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServicesStep extends StatefulWidget {
  final ServiceEntity service;

  const ServicesStep({super.key, required this.service});

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  static const List<String> _amenities = [
    'Free WiFi',
    'Parking',
    'Mobile Money Payment',
    'DSTV',
    'Wheelchair Access',
    'Refreshment',
    'Air Conditioned',
    'Free Photoshoot'
  ];

  List<String> _serviceCatalog = [];

  @override
  void initState() {
    super.initState();
    _fetchServiceCatalog();
  }

  Future<void> _fetchServiceCatalog() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('serviceList')
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data != null && data.containsKey('services')) {
        final raw = data['services'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _serviceCatalog = raw.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching service catalog: $e');
    }
  }

  void _showAddServiceDialog(BuildContext context) {
  String price = '';          
  String priceMin = '';       
  String priceMax = '';       
  String duration = '';
  String? selectedService;
  String durationUnit = 'Minutes';
  String priceType = 'Fixed'; 
  final cubit = context.read<ServiceRegistrationCubit>();

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category display (unchanged)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Category: ${widget.service.category.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Service selection (unchanged)
                if (_serviceCatalog.isNotEmpty)
                  TextField(
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push<String>(
                        dialogContext,
                        MaterialPageRoute(
                          builder: (_) => Service(item: _serviceCatalog),
                        ),
                      );
                      if (result != null) {
                        setDialogState(() => selectedService = result);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Select a service',
                      hintText: selectedService ?? 'Tap to select',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading services...',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // ---------- NEW: Price Type Toggle ----------
                Row(
                  children: [
                    const Text('Price type: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Fixed'),
                      selected: priceType == 'Fixed',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => priceType = 'Fixed');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Range'),
                      selected: priceType == 'Range',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => priceType = 'Range');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---------- Price input(s) ----------
                if (priceType == 'Fixed')
                  TextField(
                    onChanged: (v) => price = v,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price (₵)',
                      hintText: 'e.g., 50',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => priceMin = v,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Min Price (₵)',
                            hintText: 'e.g., 100',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('–', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => priceMax = v,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Max Price (₵)',
                            hintText: 'e.g., 170',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // ---------- Duration (unchanged) ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (v) => duration = v,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          hintText: 'e.g., 45',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: durationUnit,
                        items: const [
                          DropdownMenuItem(value: 'Minutes', child: Text('Min')),
                          DropdownMenuItem(value: 'Hours', child: Text('Hr')),
                        ],
                        onChanged: (value) => setDialogState(() => durationUnit = value!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // ---------- Validation ----------
                // 1. Service name
                if (selectedService == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a service')),
                  );
                  return;
                }

                // 2. Price
                String priceString;
                if (priceType == 'Fixed') {
                  final parsedPrice = int.tryParse(price);
                  if (parsedPrice == null || parsedPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid price')),
                    );
                    return;
                  }
                  priceString = parsedPrice.toString(); // store as string
                } else {
                  final min = int.tryParse(priceMin);
                  final max = int.tryParse(priceMax);
                  if (min == null || max == null || min <= 0 || max <= 0 || min > max) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid price range (min ≤ max)')),
                    );
                    return;
                  }
                  priceString = '$min - $max'; // store as "100.0 - 170.0"
                }

                // 3. Duration
                final durationValue = int.tryParse(duration);
                if (durationValue == null || durationValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid duration')),
                  );
                  return;
                }
                final durationInMinutes = (durationUnit == 'Hours')
                    ? durationValue * 60
                    : durationValue;

                // 4. Duplicate check
                final isDuplicate = widget.service.services.any(
                  (s) => s['name'].toString().toLowerCase() == selectedService!.toLowerCase(),
                );
                if (isDuplicate) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$selectedService" is already added')),
                  );
                  return;
                }

                // 5. Save
                final updated = List<Map<String, dynamic>>.from(widget.service.services)
                  ..add({
                    'name': selectedService,
                    'price': priceString,   // ✅ stored as string
                    'duration': durationInMinutes,
                  });

                cubit.updateServices(updated);  // ✅ Uncommented!
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}

  String formatDuration(int minutes) {
    if (minutes >= 60 && minutes % 60 == 0) {
      return '${minutes ~/ 60} hr';
    } else if (minutes > 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '$minutes mins';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ServiceRegistrationCubit>();
    final services = widget.service.services;
    final amenities = widget.service.amenities;

    return RefreshIndicator(
      onRefresh: () async => _fetchServiceCatalog(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cut,
              color: Theme.of(context).colorScheme.primary,
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Services & Amenities',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add the services you offer & amenities available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // ── Services list ───────────────────────────────────
            if (services.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_business, size: 40, color: Colors.grey[300]),
                    const SizedBox(width: 16),
                    Text(
                      'No services added yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              ...services.map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.task,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDuration(s['duration']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₵${s['price']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          final updated = List<Map<String, dynamic>>.from(
                            services,
                          )..remove(s);
                          cubit.updateServices(updated);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddServiceDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Service'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amenities ───────────────────────────────────────
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
                    'Amenities',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenities.map((amenity) {
                      final isSelected = amenities.contains(amenity);
                      return GestureDetector(
                        onTap: () {
                          final updated = List<String>.from(amenities);
                          if (isSelected) {
                            updated.remove(amenity);
                          } else {
                            updated.add(amenity);
                          }
                          cubit.updateAmenities(updated);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
