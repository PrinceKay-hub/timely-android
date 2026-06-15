import 'dart:convert';
import 'dart:io';
import 'package:booking/core/services/location_service.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_state.dart';
//import 'package:booking/presentaion/provider/pages/edit_service.dart';
import 'package:booking/presentaion/provider/pages/manage_service.dart';
import 'package:booking/presentaion/provider/pages/widgets/service.dart';
import 'package:booking/presentaion/screens/location/cubit/cubit/set_location_cubit.dart';
import 'package:booking/presentaion/screens/location/region_screen.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

// Service Registration Onboarding Screen
class ServiceRegistrationScreen extends StatefulWidget {
  final String userId;
  const ServiceRegistrationScreen({super.key, required this.userId});

  @override
  State<ServiceRegistrationScreen> createState() =>
      _ServiceRegistrationScreenState();
}

class _ServiceRegistrationScreenState extends State<ServiceRegistrationScreen> {
  final PageController _pageController = PageController();
  late final cubit = context.read<ServiceRegistrationCubit>();
  static const String _cacheKey = 'categories';

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _workersController = TextEditingController();
  final _phoneController = TextEditingController();

  int _currentStep = 0;
  final int _totalSteps = 7;

  // Form data
  String serviceName = '';
  String category = '';
  String description = '';
  String location = '';
  String region = '';
  String district = '';
  List<String> selectedDays = [];
  List<String> selectedAmenities = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int numberOfWorkers = 1;
  List<Map<String, dynamic>> services = [];
  String? selectedService;
  final ImagePicker _picker = ImagePicker();
  final List<String> _imageFiles = [];
  final List<String> _base64Images = [];
  List<String> serviceList = [];
  int _totalImages = 0;
  bool _isLoading = false;
  bool _isComplete = false;
  Position? currentPos;
  var box = Hive.box('myBox');

  String? phonenumber,
      countrycode = "233",
      countryname = "Ghana",
      countryiso2 = "GH";

  @override
  void initState() {
    loadService();
    fetchServices();
    super.initState();
  }

  void loadService() {
    cubit.loadServiceDataById(widget.userId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _workersController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitRegistration() {
    context.read<ServiceRegistrationCubit>().registerService(
      widget.userId,
      _imageFiles,
    );
  }

  Future<void> pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      limit: 3,
      imageQuality: 90,
    );

    for (final image in images) {
      if (_totalImages < 3) {
        _totalImages++;
        final imageBytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(imageBytes);
        _base64Images.add(base64Image);
        _imageFiles.add(image.path);
      }
    }
    setState(() {});
  }

  Future<void> pickCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (_totalImages < 3) {
      _totalImages++;
      final imageBytes = await File(image!.path).readAsBytes();
      final base64Image = base64Encode(imageBytes);
      _base64Images.add(base64Image);
      _imageFiles.add(image.path);
    }
    setState(() {});
  }

  void _deleteImage(int index) {
    _totalImages--;
    _imageFiles.removeAt(index);
    _base64Images.removeAt(index);
    setState(() {});
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteImage(index);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation() async {
    // Show loading
    setState(() {
      _isLoading = true;
      _isComplete = false;
    });

    try {
      // 1. Get current location (with error handling)
      final currentPos = await LocationService().getCurrentLocation();

      context.read<ServiceRegistrationCubit>().updateServiceCoordinates(
        currentPos!.latitude,
        currentPos.longitude,
      );

      if (mounted) {
        setState(() {
          _isComplete = true;
        });
      }
    } catch (e) {
      // Handle any unexpected errors (permission dialogs, Firestore, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always hide loading, even if an error occurred
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<String>> fetchServices() async {
    try {
      // Replace 'main' with your actual document ID
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc('serviceList') // 👈 change to your document ID
          .get();

      if (doc.exists) {
        // The field might be named 'category' (singular) or 'categories' (plural)
        // Adjust the key to match your Firestore field name.
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('services')) {
          // Ensure the value is a List and cast items to String
          List<dynamic> rawList = data['services'];
          // return rawList.map((e) => e.toString()).toList();
          setState(() {
            serviceList = rawList.map((e) => e.toString()).toList();
          });
          return serviceList;
        } else {
          print('Field "services" not found in document');
          return [];
        }
      } else {
        print('Document does not exist');
        return [];
      }
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  Future<void> _refresh() {
    fetchServices();
    return Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceRegistrationCubit, ServiceRegistrationState>(
      listener: (context, state) {
        final cubit = context.read<ServiceRegistrationCubit>();
        if (state is ServiceRegistrationSuccess) {
          cubit.resetForm();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                    'Registration Complete!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your service has been successfully registered and is pending approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/home-entry');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
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
        if (state is ServiceDeletionSuccess) {
          final userCubit = context.read<UserCubit>();
          userCubit.updateUserType('provider');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service successfully deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
          );
        }
        if (state is ServiceRegistrationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ServiceRegistrationCubit>();
        final service = cubit.currentService;

        if (state is ServiceRegistrationLoading) {
          return LoadingScreen();
        } else if (state is ServiceRegistrationDataLoaded) {
          final data = state.serviceData;

          if (state.serviceData == null) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                body: Column(
                  children: [
                    // Progress Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentStep > 0)
                                GestureDetector(
                                  onTap: _previousStep,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              Text(
                                'Step ${_currentStep + 1} of $_totalSteps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_currentStep + 1) / _totalSteps,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Page Content
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildBasicInfoStep(),
                          _buildCategoryStep(),
                          _buildDescriptionStep(),
                          _buildLocationStep(),
                          _buildWorkingHoursStep(service),
                          _buildServicesStep(),
                          _buildPhotosStep(),
                        ],
                      ),
                    ),

                    // Navigation Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canProceed() ? _nextStep : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Submit'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ManageService(data: data!);
          }
        }

        return SizedBox.shrink();
      },
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return serviceName.isNotEmpty;
      case 1:
        return category.isNotEmpty;
      case 2:
        return description.length >= 50;
      case 3:
        return location.isNotEmpty &&
            phonenumber != null &&
            phonenumber!.isNotEmpty;
      case 4:
        return startTime != null && endTime != null;
      case 5:
        return services.isNotEmpty;
      case 6:
        return _imageFiles.isNotEmpty;
      default:
        return true;
    }
  }

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
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
            'Let\'s start with the basics. What\'s your business name?',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
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
                TextField(
                  onChanged: (value) {
                    setState(() {
                      serviceName = value;
                      context
                          .read<ServiceRegistrationCubit>()
                          .updateServiceName(value);
                    });
                  },
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
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
                      onPressed: () {
                        if (numberOfWorkers > 1) {
                          setState(() {
                            numberOfWorkers--;
                            context
                                .read<ServiceRegistrationCubit>()
                                .updateServiceWorkers(numberOfWorkers);
                          });
                        }
                      },
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
                          '$numberOfWorkers ${numberOfWorkers == 1 ? 'Staff Member' : 'Staff Members'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          numberOfWorkers++;
                          context
                              .read<ServiceRegistrationCubit>()
                              .updateServiceWorkers(numberOfWorkers);
                        });
                      },
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

  // Step 2: Category Selection
  Widget _buildCategoryStep() {
    var categories = box.get(_cacheKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.category,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Category',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
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
              final isSelected = category == cat['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    category = cat['name'] as String;
                    context
                        .read<ServiceRegistrationCubit>()
                        .updateServiceCategory(category);
                  });
                },
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
                        imageUrl: cat['icon'],
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

  // Step 3: Description
  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Describe Your Business',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell potential customers about your services and what makes you unique',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Business Description',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${description.length}/500',
                      style: TextStyle(
                        color: description.length >= 50
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      description = value;
                      context
                          .read<ServiceRegistrationCubit>()
                          .updateServiceDescription(value);
                    });
                  },
                  controller: _descriptionController,
                  maxLines: 8,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText:
                        'Welcome to our salon where we provide exceptional services...',
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
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                if (description.length < 50)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Minimum 50 characters required (${50 - description.length} more)',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Location
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Business Location & Contact',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Where can customers find you?',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 10),
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
                  'Shop location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                BlocBuilder<SetLocationCubit, SetLocationState>(
                  builder: (context, state) {
                    final initialText = location.isEmpty
                        ? 'Select location'
                        : state.value;
                    return TextField(
                      onTap: () async {
                        String results = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegionsScreen(isService: true),
                          ),
                        );
                        List<String> parts = results.split(' - ');
                        if (parts.length == 2) {
                          region = parts[0]; // "Ashanti"
                          district = parts[1]; // "Kumasi Metropolitan"
                        } else {}
                        location = results;
                        setState(() {
                          context
                              .read<ServiceRegistrationCubit>()
                              .updateServiceLocation(location);
                          context
                              .read<ServiceRegistrationCubit>()
                              .updateServiceRegion(region);
                          context
                              .read<ServiceRegistrationCubit>()
                              .updateServiceDistrict(district);
                        });
                      },
                      readOnly: true,
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: initialText,
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showCautionDialog,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Set Shop Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isComplete)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),

                const SizedBox(height: 16),

                // Phone
                IntlPhoneField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'eg. 244 123456',
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
                  initialCountryCode: 'GH',
                  onChanged: (phone) {
                    phonenumber = phone.completeNumber;
                    setState(() {
                      context
                          .read<ServiceRegistrationCubit>()
                          .updateServiceNumber(phonenumber!);
                    });
                    //print(phone.completeNumber);
                  },
                  onCountryChanged: (country) {
                    setState(() {
                      countrycode = country.dialCode;
                      countryiso2 = country.code;
                      countryname = country.name;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Working Hours
  Widget _buildWorkingHoursStep(ServiceEntity service) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Working Hours',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'When are you available for appointments?',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: BlocBuilder<ServiceRegistrationCubit, ServiceRegistrationState>(
              builder: (context, state) {
                final cubit = context.read<ServiceRegistrationCubit>();
                final service = cubit.currentService;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Working Days',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: days.map((day) {
                        final isSelected = service.workingDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            final selectedDays = List<String>.from(
                              service.workingDays,
                            );
                            setState(() {
                              if (isSelected) {
                                selectedDays.remove(day);
                              } else {
                                selectedDays.add(day);
                              }
                              cubit.updateWorkingDays(selectedDays);
                            });
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
                              day,
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
                    const SizedBox(height: 24),
                    const Text(
                      'Operating Hours',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: 8, minute: 00),
                                builder: (context, child) {
                                  if (child == null) {
                                    return const SizedBox.shrink(); // or some placeholder
                                  }
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        dayPeriodColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        dayPeriodTextColor: Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  startTime = time;
                                  cubit.updateWorkingHours(
                                    WorkingHours(
                                      startHour: startTime!.hour,
                                      endHour: endTime!.hour,
                                      startMinute: startTime!.minute,
                                      endMinute: endTime!.minute,
                                    ),
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Time',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    startTime?.format(context) ?? '08:00 AM',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward, color: Colors.grey),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: 18, minute: 00),
                                builder: (context, child) {
                                  if (child == null) {
                                    return const SizedBox.shrink(); // or some placeholder
                                  }
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        dayPeriodColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        dayPeriodTextColor: Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  endTime = time;
                                  cubit.updateWorkingHours(
                                    WorkingHours(
                                      startHour: startTime!.hour,
                                      endHour: endTime!.hour,
                                      startMinute: startTime!.minute,
                                      endMinute: endTime!.minute,
                                    ),
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Time',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    endTime?.format(context) ?? '06:00 PM',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Step 6: Services
  Widget _buildServicesStep() {
    final amenities = [
      'Free WiFi',
      'Parking',
      'Mobile Money Payment',
      'DSTV',
      'Wheelchair Access',
      'Refreshment',
      'Air Conditioned',
    ];
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
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
                (service) => Container(
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
                              service['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service['duration']} min',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₵${service['price']}',
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
                          setState(() {
                            services.remove(service);
                          });
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
                onPressed: () {
                  _showAddServiceDialog(category);
                },
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

            BlocBuilder<ServiceRegistrationCubit, ServiceRegistrationState>(
              builder: (context, state) {
                final cubit = context.read<ServiceRegistrationCubit>();
                final service = cubit.currentService;
                return Container(
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: amenities.map((amenity) {
                          final isSelected = service.amenities.contains(
                            amenity,
                          );
                          return GestureDetector(
                            onTap: () {
                              final selectedAmenities = List<String>.from(
                                service.amenities,
                              );
                              setState(() {
                                if (isSelected) {
                                  selectedAmenities.remove(amenity);
                                } else {
                                  selectedAmenities.add(amenity);
                                }
                                cubit.updateAmenities(selectedAmenities);
                              });
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog(String category) {
    //String serviceName = '';
    String price = '';
    String duration = '';
    String? selectedService;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get services for the normalized category
          List<String> availableServices = serviceList;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Add New Service'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category display (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.category,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Category: ${category.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Service selection dropdown (conditional based on category)
                  if (availableServices.isNotEmpty)
                    TextField(
                      readOnly: true,
                      onTap: () async {
                        final results = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Service(item: availableServices),
                          ),
                        );
                        setState(() {
                          selectedService = results;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select a service',
                        hintText: selectedService,
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No services available for "$category"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check the category or add a custom service',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => price = value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (₵)',
                      hintText: 'e.g., 50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => duration = value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: 'e.g., 45',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              BlocBuilder<ServiceRegistrationCubit, ServiceRegistrationState>(
                builder: (context, state) {
                  final cubit = context.read<ServiceRegistrationCubit>();
                  return ElevatedButton(
                    onPressed: () {
                      if (selectedService != null &&
                          price.isNotEmpty &&
                          duration.isNotEmpty) {
                        setState(() {
                          services.add({
                            'name': selectedService,
                            'price': int.parse(price),
                            'duration': int.parse(duration),
                          });
                          cubit.updateServices(services);
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Add'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Step 7: Photos
  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.photo_camera,
            color: Theme.of(context).colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Photos',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Showcase your business with great photos',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add at least 3 photos for better visibility',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildImageGrid(),
          const SizedBox(height: 16),
          if (_imageFiles.length < 3) _buildUploadButton(),
          _buildImageCount(),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_imageFiles.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _imageFiles.length,
      itemBuilder: (context, index) =>
          _buildImageItem(_imageFiles[index], index),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No images added yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imagePath, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _showDeleteDialog(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: ((builder) => bottomsheet()),
          );
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Add Photos'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${_imageFiles.length} of 3 images selected',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  // select path to get inage
  Widget bottomsheet() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Select where to choose image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.cancel, size: 30, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).highlightColor,
            ),
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    pickCamera();
                    Navigator.of(context).pop();
                  },
                  trailing: const Icon(Icons.camera_alt_outlined),
                  title: Text(
                    "Open Camera",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Divider(height: 1, color: Colors.grey.shade400),
                ),
                ListTile(
                  onTap: () {
                    pickImage();
                    Navigator.of(context).pop();
                  },
                  trailing: const Icon(Icons.image_outlined),
                  title: Text(
                    "Choose from Gallery",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showCautionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you at the precise location of your business? Setting an accurate location helps customers find you easily. You can adjust it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, I will set it later'),
          ),
          ElevatedButton(
            onPressed: () {
              _pickLocation();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, I am there'),
          ),
        ],
      ),
    );
  }
}
