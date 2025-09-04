import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  // Stream user document for realtime updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return _usersCol.doc(uid).snapshots();
  }

  // Ensure user doc exists (call after signup)
  Future<void> ensureUserDoc({
    required String uid,
    required String email,
    String? name,
  }) async {
    final docRef = _usersCol.doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'email': email,
        'name': name ?? '',
        'phone': '',
        'address': {
          'line1': '',
          'city': '',
          'postalCode': '',
          'country': '',
        },
        'avatarUrl': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update profile fields (name, phone, address)
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (data.isNotEmpty) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCol.doc(uid).set(data, SetOptions(merge: true));
    }
  }

  // Upload avatar image file to Storage and update user doc with URL
  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _usersCol.doc(uid).set({
      'avatarUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  // Remove avatar (delete storage file and clear url in doc)
  Future<void> removeAvatar({required String uid}) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    try {
      await ref.delete();
    } catch (_) {
      // ignore if file not found
    }
    await _usersCol.doc(uid).set({
      'avatarUrl': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get current user doc once
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _usersCol.doc(uid).get();
  }
}
