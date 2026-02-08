import 'package:care_nexus/services/location_permission_service.dart'
    hide PermissionService;
import 'package:care_nexus/widgets/sos_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';
import '../chats/chatpage.dart';
import 'appointments_page.dart';
import 'health_records_page.dart';
import 'prescriptions_page.dart';
import 'emergency_page.dart';
import 'widgets/sos_button.dart'; // Ensure this path is correct
import 'package:care_nexus/services/permission_service.dart';
// Ensure this path is correct

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  late Future<Map<String, dynamic>?> userFuture;

  @override
  void initState() {
    super.initState();
    userFuture = getUserData();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;
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

  String _getChatId(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? "${id1}_$id2" : "${id2}_$id1";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        leading: Builder(
          builder: (context) {
            final display = user?.displayName;
            final initial = (display?.isNotEmpty == true)
                ? display![0].toUpperCase()
                : (user?.email?.isNotEmpty == true
                      ? user!.email![0].toUpperCase()
                      : 'U');
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: CircleAvatar(
                radius: 18,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: Colors.blue.shade700,
                child: user?.photoURL == null
                    ? Text(initial, style: const TextStyle(color: Colors.white))
                    : null,
              ),
            );
          },
        ),
        title: const Text(
          "Patient Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade600),
              child: const Text(
                "Patient App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Appointments"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text("Health Records"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: logout,
            ),
          ],
        ),
      ),
      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "doctorChat",
            backgroundColor: const Color(0xFF2563eb),
            onPressed: () {
              if (user != null) {
                final chatId = _getChatId(
                  user!.uid,
                  'doctor_001',
                ); // Example dynamic ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: chatId,
                      senderId: user!.uid,
                      receiverId: 'doctor_001',
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const AiGlowButton(),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                userFuture = getUserData();
              });
            },
            child: FutureBuilder<Map<String, dynamic>?>(
              future: userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData)
                  return const Center(child: Text("Unable to load user data"));

                final userData = snapshot.data!;
                final name = userData['name'] ?? user?.displayName ?? "User";
                final email = userData['email'] ?? user?.email ?? "";

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(name, email),
                      const SizedBox(height: 25),
                      const _SectionTitle(
                        icon: Icons.flash_on,
                        title: "Quick Actions",
                      ),
                      const SizedBox(height: 12),
                      _buildGrid(context),
                      const SizedBox(height: 25),
                      const _SectionTitle(
                        icon: Icons.history,
                        title: "Recent Activity",
                      ),
                      const SizedBox(height: 12),
                      const ActivityItem(
                        title: "Appointment with Dr. John",
                        date: "Today • 2:30 PM",
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const ActivityItem(
                        title: "Medicine refill request",
                        date: "Yesterday",
                        icon: Icons.local_pharmacy,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 80), // Space for SOS button
                    ],
                  ),
                );
              },
            ),
          ),
          // Positioned SOS Button
          const Positioned(bottom: 150, right: 50, child: SosButton()),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome",
            style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(email, style: TextStyle(color: Colors.white.withOpacity(.9))),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ActionCard(
          icon: Icons.calendar_today,
          title: "Appointments",
          subtitle: "Book & manage",
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentsPage()),
          ),
        ),
        ActionCard(
          icon: Icons.medical_services,
          title: "Health Records",
          subtitle: "Past reports",
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthRecordsPage()),
          ),
        ),
        ActionCard(
          icon: Icons.medication,
          title: "Prescriptions",
          subtitle: "Your medicines",
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrescriptionsPage()),
          ),
        ),
        ActionCard(
          icon: Icons.emergency,
          title: "Emergency",
          subtitle: "Need help?",
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyPage()),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// --- Fix: Properly passing user data to AI Button ---
class AiGlowButton extends StatefulWidget {
  const AiGlowButton({super.key});
  @override
  State<AiGlowButton> createState() => _AiGlowButtonState();
}

class _AiGlowButtonState extends State<AiGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.microtask(() async {
      try {
        await PermissionService.requestLocationPermission();
      } catch (e) {
        debugPrint(e.toString());
      }
    });

    Future.microtask(() async {
      try {
        await PermissionService.requestAllPermissions();
      } catch (e) {
        debugPrint("PERMISSION ERROR: $e");
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.35),
                blurRadius: 20 + (_controller.value * 10),
                spreadRadius: 1,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: "aiChatBtn",
            backgroundColor: const Color(0xFF4E8E9E),
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text("AI Chat", style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: "ai_chat_${currentUser.uid}",
                      senderId: currentUser.uid,
                      receiverId: "AI_BOT",
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// Remaining helper widgets (ActionCard, ActivityItem, _SectionTitle) stay as they were in your code...
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String title, date;
  final IconData icon;
  final Color color;
  const ActivityItem({
    super.key,
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(date),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
