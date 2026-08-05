import 'package:booking/data/models/service_model.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_state.dart';
import 'package:booking/presentaion/provider/pages/steps/basic_info_step.dart';
import 'package:booking/presentaion/provider/pages/steps/category_step.dart';
import 'package:booking/presentaion/provider/pages/steps/description_step.dart';
import 'package:booking/presentaion/provider/pages/steps/location_step.dart';
import 'package:booking/presentaion/provider/pages/steps/photos_step.dart';
import 'package:booking/presentaion/provider/pages/steps/services_step.dart';
import 'package:booking/presentaion/provider/pages/steps/working_hours_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServiceForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? userId; //
  final bool? isProvider;
  const ServiceForm({super.key, this.data, this.userId, this.isProvider});

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 7;
  late ServiceModel service;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ServiceRegistrationCubit>();
    if (widget.data != null) {
      // Edit mode – load existing data
      final service = ServiceModel.fromJson(widget.data!);
      cubit.setServiceData(service);
    } else {
      // New mode – reset and set providerId
      cubit.resetForm();
      if (widget.userId != null) {
        cubit.updateProviderId(widget.userId!);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _submit() {
    final cubit = context.read<ServiceRegistrationCubit>();
    final imageFiles = PhotosStep.imageFilesOf(context);

    if (widget.data != null) {
      if (widget.data!['status'] == 'rejected') {
        cubit.updateServiceStatus('pending');
      }
      cubit.updateService(imageFiles);
    } else {
      cubit.registerService(imageFiles, widget.isProvider!);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void jumpToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _canProceed(ServiceEntity service) {
    switch (_currentStep) {
      case 0:
        return service.name.isNotEmpty;
      case 1:
        return service.category.isNotEmpty;
      case 2:
        return service.description.length >= 50;
      case 3:
        return service.location.isNotEmpty && service.number.isNotEmpty && service.landmark.isNotEmpty;
      case 4:
        final startMin =
            service.workingHours.startHour * 60 +
            service.workingHours.startMinute;
        final endMin =
            service.workingHours.endHour * 60 + service.workingHours.endMinute;
        return service.workingDays.isNotEmpty && endMin > startMin;
      case 5:
        return service.services.isNotEmpty;
      case 6:
        return _imageCount > 0 || service.images.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceRegistrationCubit, ServiceRegistrationState>(
      listener: (context, state) {
        if (state is ServiceRegistrationSuccess) {
          context.read<ServiceRegistrationCubit>().resetForm();
          _showSuccessDialog('Registration');
        } else if (state is ServiceUpdateSuccess) {
          context.read<ServiceRegistrationCubit>().resetForm();
          _showSuccessDialog('Update');
        } else if (state is ServiceRegistrationError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
      },
      builder: (context, state) {
        ServiceEntity service;
        if (state is ServiceRegistrationUpdated) {
          service = state.service;
        } else if (state is ServiceRegistrationDataLoaded) {
          // This might happen if you load from elsewhere – fallback to current service
          service = context.read<ServiceRegistrationCubit>().currentService;
        } else {
          // For initial or any other state, use currentService
          service = context.read<ServiceRegistrationCubit>().currentService;
        }
        if (state is ServiceRegistrationLoading) {
          return LoadingScreen();
        }

        // Now build the UI with this service
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            body: Column(
              children: [
                _buildHeader(widget.data != null ? 'Edit' : 'New'),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BasicInfoStep(
                        service: service,
                        onOpenChat: _launchChatAndJump,
                      ),
                      CategoryStep(service: service),
                      DescriptionStep(service: service),
                      LocationStep(service: service),
                      WorkingHoursStep(service: service),
                      ServicesStep(service: service),
                      PhotosStep(
                        key: PhotosStep.globalKey,
                        service: service,
                        onImageCountChanged: (count) {
                          setState(() {
                            _imageCount = count;
                          });
                        },
                        onDeleteExistingImage: (imageUrl) {
                          context.read<ServiceRegistrationCubit>().markImageForDeletion(imageUrl);
                        },
                      ),
                    ],
                  ),
                ),
                _buildNavBar(service),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String title) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _currentStep > 0
                    ? _previousStep
                    : () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentStep > 0 ? Icons.arrow_back : Icons.close,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '$title Step ${_currentStep + 1} of $_totalSteps',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(ServiceEntity service) {
    return Container(
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
            onPressed: _canProceed(service) ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == _totalSteps - 1 ? 'Submit' : 'Continue',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchChatAndJump() async {
    await BasicInfoStep.launchChat(
      context,
      context.read<ServiceRegistrationCubit>(),
    );
    if (mounted) jumpToStep(3);
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            Text(
              '$title Complete!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (title == 'Registration')
              Text(
                'Your service has been successfully registered.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              Text(
                'Your service has been successfully updated.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  //context.go('/home-entry');
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
}
