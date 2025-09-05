
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreenWithMap extends StatefulWidget {
  const SignupScreenWithMap({super.key});

  @override
  SignupScreenWithMapState createState() => SignupScreenWithMapState();
}

class SignupScreenWithMapState extends State<SignupScreenWithMap> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _shopNameController = TextEditingController();
  String? _selectedTownship;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = false;

  final List<String> _townships = [
    'Township 1',
    'Township 2',
    'Township 3',
    // Add more townships as needed
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

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
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks[0];
      setState(() {
        _addressController.text =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
      });
    } catch (e) {
      // handle error
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final usersQuery =
            await FirebaseFirestore.instance.collection('users').limit(1).get();
        final isFirstUser = usersQuery.docs.isEmpty;
        final role = isFirstUser ? 'admin' : 'user';

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _usernameController.text,
          'shopName': _shopNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'township': _selectedTownship,
          'location': GeoPoint(
              _selectedLocation!.latitude, _selectedLocation!.longitude),
          'role': role,
        });

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/products');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a username' : null,
                ),
                TextFormField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a shop name' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an email' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a phone number' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an address' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTownship,
                  items: _townships.map((String township) {
                    return DropdownMenuItem<String>(
                      value: township,
                      child: Text(township),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTownship = newValue;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Township'),
                  validator: (value) =>
                      value == null ? 'Please select a township' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: GoogleMap(
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
                      _getAddressFromLatLng(
                          location.latitude, location.longitude);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signup,
                        child: const Text('Sign Up'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
