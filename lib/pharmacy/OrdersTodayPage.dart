import 'package:flutter/material.dart';

class OrdersTodayPage extends StatelessWidget {
  const OrdersTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders Today")),
      body: const Center(child: Text("Today's Orders Here")),
    );
  }
}
