import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Orders")),
      body: StreamBuilder<QuerySnapshot>(
        // GET DATA: Listen for orders where medicalId matches current user
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where(
              'medicalId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .orderBy('createdAt', descending: true) // Newest orders first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No orders yet"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var order = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              var status = order['status'] ?? "Pending";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    "Patient: ${order['patientName'] ?? 'Anonymous'}",
                  ),
                  subtitle: Text(
                    "Items: ${order['itemsSummary']}\nTotal: \$${order['totalPrice']}",
                  ),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: status == "Pending"
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                  ),
                  onTap: () => _updateOrderStatus(
                    context,
                    snapshot.data!.docs[i].id,
                    status,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateOrderStatus(
    BuildContext context,
    String orderId,
    String currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check, color: Colors.green),
            title: const Text("Mark as Completed"),
            onTap: () {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': 'Completed'});
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text("Mark as Cancelled"),
            onTap: () {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': 'Cancelled'});
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
