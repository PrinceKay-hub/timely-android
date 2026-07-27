import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_state.dart';
import 'package:booking/presentaion/provider/pages/manage_service.dart';
import 'package:booking/presentaion/provider/pages/widgets/service_from.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServiceRegistrationScreen extends StatefulWidget {
  final String userId;
  const ServiceRegistrationScreen({super.key, required this.userId});

  @override
  State<ServiceRegistrationScreen> createState() =>
      _ServiceRegistrationScreenState();
}

class _ServiceRegistrationScreenState extends State<ServiceRegistrationScreen> {
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    context.read<ServiceRegistrationCubit>().loadServicesByProvider(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceRegistrationCubit, ServiceRegistrationState>(
      listener: (context, state) {
        if (state is ServiceRegistrationDataLoaded) {
          setState(() {
            _services = state.services;
          });
        } else if (state is ServiceRegistrationSuccess ||
            state is ServiceUpdateSuccess) {
          // After a successful create or update, reload the list
          context.read<ServiceRegistrationCubit>().loadServicesByProvider(widget.userId);
        } else if (state is ServiceDeletionSuccess) {
          // After deletion, reload the list
          context.read<ServiceRegistrationCubit>().loadServicesByProvider(widget.userId);
        }
      },
      builder: (context, state) {
        if (state is ServiceRegistrationLoading && _services.isEmpty) {
          return const LoadingScreen();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            title: Text(
              'Manage Services (${_services.length})',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _services.isEmpty
              ? _buildEmptyState()
              : ManageService(service: _services),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceForm(
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, color: Theme.of(context).colorScheme.primary, size: 60),
          const Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'You have not registered any service yet. Add one now to start receiving bookings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceForm(
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: const Text('Add Service'),
          ),
        ],
      ),
    );
  }
}