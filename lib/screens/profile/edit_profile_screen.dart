import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  bool _loading = false;
  File? _avatarFile;
  String? _avatarUrl;

  final _picker = ImagePicker();
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      _nameCtrl.text = user.displayName ?? '';
      // load Firestore user doc to prefill address/phone/avatar
      _loadUserDoc(user.uid);
    }
  }

  Future<void> _loadUserDoc(String uid) async {
    final snap = await _profileService.getUserDoc(uid);
    final data = snap.data();
    if (data != null) {
      setState(() {
        _phoneCtrl.text = data['phone'] ?? '';
        final address = data['address'] as Map<String, dynamic>? ?? {};
        _line1Ctrl.text = address['line1'] ?? '';
        _cityCtrl.text = address['city'] ?? '';
        _postalCtrl.text = address['postalCode'] ?? '';
        _countryCtrl.text = address['country'] ?? '';
        _avatarUrl = data['avatarUrl'] ?? '';
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update displayName via FirebaseAuth (so FirebaseAuth.currentUser.displayName is set)
      final newName = _nameCtrl.text.trim();
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
        await user.reload();
      }

      // Update email if changed
      final newEmail = _emailCtrl.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        // For security, Firebase may require recent login. Caller should handle re-auth if needed.
        await user.verifyBeforeUpdateEmail(newEmail);
        // Optionally send email verification:
        await user.sendEmailVerification();
      }

      // Update password if provided
      final newPassword = _newPasswordCtrl.text;
      if (newPassword.isNotEmpty) {
        // For security, this usually requires recent signin (reauthenticate). Handle errors in UI.
        await user.updatePassword(newPassword);
      }

      // Upload avatar if new file chosen
      if (_avatarFile != null) {
        final url = await _profileService.uploadAvatar(uid: user.uid, file: _avatarFile!);
        _avatarUrl = url;
      }

      // Update Firestore profile fields
      await _profileService.updateProfile(
        uid: user.uid,
        name: newName,
        phone: _phoneCtrl.text.trim(),
        address: {
          'line1': _line1Ctrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      if (!mounted) return;
      Navigator.pop(context);
    } on Exception catch (e) {
      // Common errors: requires-recent-login for sensitive operations
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _line1Ctrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: _avatarFile != null
                          ? CircleAvatar(radius: 48, backgroundImage: FileImage(_avatarFile!))
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(_avatarUrl!))
                              : const CircleAvatar(radius: 48, child: Icon(Icons.person))),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo),
                      label: const Text('Change Avatar'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Name ထည့်ပါ' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email ထည့်ပါ';
                        if (!v.contains('@')) return 'အမှန်တကယ် Email ဖြင့်ဖြည့်ပါ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      decoration: const InputDecoration(labelText: 'New Password (leave blank to keep)'),
                      obscureText: true,
                    ),
                    const Divider(height: 24),
                    TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _line1Ctrl, decoration: const InputDecoration(labelText: 'Address line 1')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _postalCtrl, decoration: const InputDecoration(labelText: 'Postal Code')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'Country')),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _submit, child: const Text('Save')),
                  ],
                ),
              ),
            ),
    );
  }
}
