
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tabs/products_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/settings_tab.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUserRole());
  }

  Future<void> _checkUserRole() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (!doc.exists) {
        throw Exception("User data not found");
      }
      _userData = doc.data();
      if (_userData!['role'] != 'admin') {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/products'); // or some other non-admin page
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_userData == null || _userData!['role'] != 'admin') {
        // This is a fallback, in case the redirect in initState fails.
        return const Scaffold(
            body: Center(
                child: Text(
                    "You don't have permission to view this page.",),),);
    }


    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'Products'),
              Tab(icon: Icon(Icons.receipt), text: 'Orders'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.announcement), text: 'Announcement'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProductsTab(),
            OrdersTab(),
            UsersTab(),
            AnnouncementsTab(),
            ReportsTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}
