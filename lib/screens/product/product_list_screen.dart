import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Normally, you'd query Firebase for products.
    return Scaffold(
      appBar: AppBar(title: Text('Moegyishop Products')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, idx) => ListTile(
          title: Text('Product #$idx'),
          subtitle: Text('Product description here'),
          onTap: () {
            Navigator.pushNamed(context, '/product_detail', arguments: idx);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/cart'),
        child: Icon(Icons.shopping_cart),
      ),
    );
  }
}
