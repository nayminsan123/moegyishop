import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildAvatar(String? url, double size) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(radius: size / 2, child: Icon(Icons.person, size: size * 0.6));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }
    final uid = user.uid;
    final profileService = ProfileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            tooltip: 'Sign out',
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileService.userDocStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data;
          final data = doc?.data() ?? {};
          final name = data['name'] as String? ?? user.displayName ?? '';
          final email = user.email ?? data['email'] as String? ?? '';
          final phone = data['phone'] as String? ?? '';
          final avatarUrl = data['avatarUrl'] as String? ?? '';
          final address = (data['address'] as Map<String, dynamic>?) ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAvatar(avatarUrl, 100),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email),
                const SizedBox(height: 8),
                if (phone.isNotEmpty) Text('Phone: $phone'),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Shipping Address'),
                    subtitle: Text(
                      '${address['line1'] ?? ''}\n${address['city'] ?? ''} ${address['postalCode'] ?? ''}\n${address['country'] ?? ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile/edit', arguments: {'uid': uid});
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to email/password change flow or show a dialog
                    Navigator.pushNamed(context, '/profile/edit', arguments: {'uid': uid, 'openCredentialsTab': true});
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Email / Password'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
