/*import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition; // optional, e.g., current location

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  late GoogleMapController mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  // Default center (e.g., a fallback)
  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870); // San Francisco

  @override
  void initState() {
    super.initState();
    // If an initial position is provided (e.g., current location), use it as the selected location.
    _selectedLocation = widget.initialPosition;
    if (_selectedLocation != null) {
      _updateMarker(_selectedLocation!);
    }
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _updateMarker(latLng);
    });
  }

  void _updateMarker(LatLng latLng) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: latLng,
        draggable: true,     // allow user to drag the marker
        onDragEnd: (newPos) {
          setState(() {
            _selectedLocation = newPos;
            _updateMarker(newPos);
          });
        },
      ),
    );
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap on the map to select a location')),
      );
      return;
    }

    // Save to Firestore (same as current location method)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(user.uid)
          .set({
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Optionally pop with result
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Shop Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text('Confirm', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition ?? _defaultCenter,
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController mapController) {
          mapController = mapController;
          googleMapCompleterController.complete(
            mapController,
          );},
        onTap: _onMapTapped,
        markers: _markers,
        myLocationEnabled: true,          // show user's current location dot
        myLocationButtonEnabled: true,    // show button to center on user
      ),
    );
  }
}*/