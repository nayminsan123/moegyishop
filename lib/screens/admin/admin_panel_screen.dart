import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Add New Product'),
            onTap: () {},
          ),
          ListTile(
            title: Text('Manage Products'),
            onTap: () {},
          ),
          ListTile(
            title: Text('Manage Orders'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
