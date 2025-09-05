
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  MapSelectionScreenState createState() => MapSelectionScreenState();
}

class MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWithPermissionHandler();
  }

  Future<void> _getCurrentLocationWithPermissionHandler() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _markers.add(
            Marker(
              markerId: const MarkerId('selectedLocation'),
              position: _selectedLocation!,
            ),
          );
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
        _getAddressFromLatLng(position.latitude, position.longitude);
      } catch (e) {
        // Handle error
      }
    } else if (status.isDenied) {
      // Handle denied
    } else if (status.isPermanentlyDenied) {
      // Handle permanently denied
      openAppSettings();
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks[0];
      setState(() {
        _selectedAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
      });
    } catch (e) {
      // handle error
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null && _selectedAddress != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmSelection,
          )
        ],
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _selectedLocation ?? const LatLng(16.8409, 96.1735),
          zoom: 15,
        ),
        markers: _markers,
        onTap: (location) {
          setState(() {
            _selectedLocation = location;
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('selectedLocation'),
                position: _selectedLocation!,
              ),
            );
          });
          _getAddressFromLatLng(location.latitude, location.longitude);
        },
      ),
    );
  }
}
