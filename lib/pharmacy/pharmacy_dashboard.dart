import 'package:care_nexus/doctor/ReportsPage.dart';
import 'package:care_nexus/pharmacy/InventoryPage.dart';
import 'package:care_nexus/pharmacy/LowStockPage.dart';
import 'package:care_nexus/pharmacy/MedicinesPage.dart';
import 'package:care_nexus/pharmacy/OrdersPage.dart';
import 'package:care_nexus/pharmacy/OrdersTodayPage.dart';
import 'package:care_nexus/pharmacy/ProductsPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';

class MedicalDashboard extends StatefulWidget {
  const MedicalDashboard({super.key});

  @override
  State<MedicalDashboard> createState() => _MedicalDashboardState();
}

class _MedicalDashboardState extends State<MedicalDashboard> {
  final user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();
    return doc.data();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Store Dashboard"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error loading user data"));
          }

          final userData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${userData['name']}! 💊",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['email'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProductsPage()));
                        },
                        child: FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('products')
                              .where('medicalId', isEqualTo: user!.uid)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const _StatCard(
                                label: "Products",
                                value: "...",
                                color: Colors.blue,
                              );
                            }

                            final count = snapshot.data!.docs.length;

                            return _StatCard(
                              label: "Products",
                              value: count.toString(),
                              color: Colors.blue,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OrdersTodayPage()));
                        },
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('medicalId', isEqualTo: user!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const _StatCard(
                                label: "Orders Today",
                                value: "...",
                                color: Colors.green,
                              );
                            }

                            final count = snapshot.data!.docs.length;

                            return _StatCard(
                              label: "Orders Today",
                              value: count.toString(),
                              color: Colors.green,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LowStockPage()));
                        },
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .where('medicalId', isEqualTo: user!.uid)
                              .where('quantity', isLessThan: 10)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const _StatCard(
                                label: "Low Stock",
                                value: "...",
                                color: Colors.orange,
                              );
                            }

                            final count = snapshot.data!.docs.length;

                            return _StatCard(
                              label: "Low Stock",
                              value: count.toString(),
                              color: Colors.orange,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Quick Actions Section
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _ActionCard(
                      icon: Icons.inventory,
                      title: "Inventory",
                      subtitle: "Manage stock",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryPage()),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.shopping_cart,
                      title: "Orders",
                      subtitle: "View orders",
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersPage()),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.local_pharmacy,
                      title: "Medicines",
                      subtitle: "Add/update",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MedicinesPage()),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.assessment,
                      title: "Reports",
                      subtitle: "Sales analytics",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Recent Orders
                const Text(
                  "Recent Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .orderBy('timestamp', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = snapshot.data!.docs;

                    if (orders.isEmpty) {
                      return const Text("No recent orders");
                    }

                    return Column(
                      children: orders.map((doc) {
                        final data = doc.data();

                        String status = data['status'];
                        Color statusColor;

                        if (status == "Completed") {
                          statusColor = Colors.green;
                        } else if (status == "Processing") {
                          statusColor = Colors.orange;
                        } else {
                          statusColor = Colors.blue;
                        }

                        return _OrderCard(
                          orderId: data['orderId'],
                          customerName: data['customerName'],
                          medicines: data['medicines'].toString(),
                          amount: data['amount'].toString(),
                          status: status,
                          statusColor: statusColor,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String medicines;
  final String amount;
  final String status;
  final Color statusColor;

  const _OrderCard({
    required this.orderId,
    required this.customerName,
    required this.medicines,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              customerName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              medicines,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
