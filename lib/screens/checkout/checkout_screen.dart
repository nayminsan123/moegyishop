import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(labelText: 'Shipping Address')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Pay & Place Order (Demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
