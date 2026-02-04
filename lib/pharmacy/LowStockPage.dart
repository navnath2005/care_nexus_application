import 'package:flutter/material.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Low Stock")),
      body: const Center(child: Text("Low Stock Items Here")),
    );
  }
}
