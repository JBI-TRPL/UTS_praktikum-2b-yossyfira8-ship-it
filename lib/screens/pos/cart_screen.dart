// lib/screens/pos/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/screens/pos/payment_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<int, int> cart; // productId -> quantity

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartDetailsFuture;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cartDetailsFuture = _getCartDetails();
  }

  Future<List<Map<String, dynamic>>> _getCartDetails() async {
    List<Map<String, dynamic>> details = [];
    int currentTotal = 0;
    for (var entry in widget.cart.entries) {
      Product product = await DatabaseHelper.instance.getProductById(entry.key);
      details.add({'product': product, 'quantity': entry.value});
      currentTotal += product.price * entry.value;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _total = currentTotal;
        });
      }
    });
    return details;
  }

  // Method ini sekarang hanya mengarahkan ke PaymentScreen
  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentScreen(cart: widget.cart, totalAmount: _total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOTAL')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keranjang kosong.'));
          }

          final cartItems = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: 80), // Beri ruang untuk tombol
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final Product product = item['product'];
                    final int quantity = item['quantity'];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('$quantity'),
                      ),
                      title: Text(product.name),
                      trailing: Text('Rp. ${product.price * quantity}'),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Rp. $_total',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _total > 0 ? _goToPayment : null,
                child: const Text('Bayar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
