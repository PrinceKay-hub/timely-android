import 'package:booking/core/services/location_service.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/screens/location/region_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LocationStep extends StatefulWidget {
  final ServiceEntity service;

  const LocationStep({super.key, required this.service});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isLocating = false;
  bool _locationSet = false;
  double? _lastLat;
  double? _lastLng;

  // Controllers are created once and kept in sync, instead of being
  // rebuilt on every frame — avoids cursor jumps and flicker while typing.
  late final TextEditingController _locationController;
  late final TextEditingController _landmarkController;

  @override
  void initState() {
    super.initState();
    _locationController =
        TextEditingController(text: widget.service.location);
    _landmarkController =
        TextEditingController(text: widget.service.landmark);
    if (widget.service.latitude != null) {
      _locationSet = true;
      _lastLat = widget.service.latitude;
      _lastLng = widget.service.longitude;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null && mounted) {
        final cubit = context.read<ServiceRegistrationCubit>();
        cubit.updateServiceCoordinates(
              pos.latitude,
              pos.longitude,
            );
          
        final address = await LocationService().getAddressFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (address != null && address.isNotEmpty)
        setState(() {
          _locationSet = true;
          _lastLat = pos.latitude;
          _lastLng = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop location set successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showCautionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.my_location,
            color: Theme.of(context).colorScheme.primary, size: 32),
        title: const Text(
          'Confirm Location',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you at the precise location of your business right now? '
          'Setting an accurate location helps customers find you easily. '
          'You can adjust it later.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not right now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, set it now'),
          ),
        ],
      ),
    );
  }

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

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ServiceRegistrationCubit>();
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: primary, size: 60),
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
          const SizedBox(height: 16),

          // ── Location section ─────────────────────────────────
          _sectionCard(
            children: [
              _sectionLabel('Shop location (Region & District)'),
              const SizedBox(height: 10),
              TextField(
                controller: _locationController,
                readOnly: true,
                onTap: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RegionsScreen(isService: true)),
                  );
                  if (result == null) return;
                  final parts = result.split(' - ');
                  cubit.updateServiceLocation(result);
                  if (parts.length == 2) {
                    cubit.updateServiceRegion(parts[0]);
                    cubit.updateServiceDistrict(parts[1]);
                  }
                  setState(() => _locationController.text = result);
                },
                decoration: _fieldDecoration(
                  hint: 'Select region & district',
                  icon: Icons.location_on_outlined,
                ).copyWith(
                  suffixIcon: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 20),

              // ── Precise location button + status ─────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _showCautionDialog,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _locationSet
                                  ? Icons.check_circle
                                  : Icons.my_location,
                              color: _locationSet ? Colors.green : primary,
                            ),
                      label: Text(_isLocating
                          ? 'Getting location…'
                          : _locationSet
                              ? 'Location set — tap to update'
                              : 'Set Precise Shop Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: _locationSet ? Colors.green : primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_locationSet)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastLat != null && _lastLng != null
                              ? 'Precise location saved (${_lastLat!.toStringAsFixed(4)}, ${_lastLng!.toStringAsFixed(4)})'
                              : 'Precise location saved',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.amber[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stand at your business premises, then tap the '
                          'button above to pin your exact location.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // ── Landmark ────────────────────────────────────
              _sectionLabel('Nearest Landmark'),
              const SizedBox(height: 8),
              TextField(
                controller: _landmarkController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => cubit.updateServiceLandmark(value),
                decoration: _fieldDecoration(
                  hint: 'e.g., Adum opposite PZ',
                  icon: Icons.landscape_outlined,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Helps customers find you when GPS isn\'t precise enough.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Contact section ──────────────────────────────────
          _sectionCard(
            children: [
              _sectionLabel('Contact Number'),
              const SizedBox(height: 10),
              IntlPhoneField(
                initialValue: widget.service.number.isNotEmpty
                    ? widget.service.number
                    : null,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration(
                  hint: '24 123 4567',
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                ),
                initialCountryCode: 'GH',
                onChanged: (phone) =>
                    cubit.updateServiceNumber(phone.completeNumber),
              ),
              const SizedBox(height: 6),
              Text(
                'This is the number customers will use to reach you.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}