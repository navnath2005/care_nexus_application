import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';
import '../chats/chatpage.dart';
import 'appointments_page.dart';
import 'health_records_page.dart';
import 'prescriptions_page.dart';
import 'emergency_page.dart';
import 'ai_chat_page.dart';

import 'package:google_generative_ai/google_generative_ai.dart';

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
    setState(() {
      userFuture = getUserData();
    });
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

  String _getChatId(String patientId, String doctorId) {
    return patientId.compareTo(doctorId) < 0
        ? "${patientId}_$doctorId"
        : "${doctorId}_$patientId";
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
            final photoUrl = user?.photoURL;
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
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                backgroundColor: Colors.blue.shade700,
                child: photoUrl == null
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
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
              ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xFF2563eb),
            onPressed: () {
              if (user != null) {
                final patientUid = FirebaseAuth.instance.currentUser!.uid;
                final doctorUid = 'pat_001'; // Example doctor ID
                final chatId = _getChatId('patient_${user!.uid}', 'pat_001');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: chatId,
                      senderId: user!.uid,
                      receiverId: 'pat_001',
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

      // === FIXED: single body (removed duplicate / incomplete FutureBuilder blocks) ===
      body: RefreshIndicator(
        onRefresh: () async {
          final data = await getUserData();
          setState(() {
            userFuture = Future.value(data);
          });
        },
        child: FutureBuilder<Map<String, dynamic>?>(
          future: userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("Unable to load user data"));
            }

            final userData = snapshot.data!;
            final name = userData['name'] ?? user?.displayName ?? "User";
            final email = userData['email'] ?? user?.email ?? "";
            final photoUrl = userData['photoUrl'] ?? user?.photoURL ?? "";

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Container(
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
                          style: TextStyle(
                            color: Colors.white.withOpacity(.9),
                            fontSize: 14,
                          ),
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
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// QUICK ACTIONS
                  const _SectionTitle(
                    icon: Icons.flash_on,
                    title: "Quick Actions",
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AppointmentsPage()),
                          );
                        },
                      ),
                      ActionCard(
                        icon: Icons.medical_services,
                        title: "Health Records",
                        subtitle: "Past reports",
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HealthRecordsPage()),
                          );
                        },
                      ),
                      ActionCard(
                        icon: Icons.medication,
                        title: "Prescriptions",
                        subtitle: "Your medicines",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrescriptionsPage()),
                          );
                        },
                      ),
                      ActionCard(
                        icon: Icons.emergency,
                        title: "Emergency",
                        subtitle: "Need help?",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EmergencyPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// RECENT ACTIVITY
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

                  const ActivityItem(
                    title: "Lab report uploaded",
                    date: "2 days ago",
                    icon: Icons.file_download,
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// REUSABLE WIDGETS BELOW ▼

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        )
      ],
    );
  }
}

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
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.smart_toy),
            label: const Text("AI Chat"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatPage()),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedAiIcon extends StatefulWidget {
  const AnimatedAiIcon({super.key});

  @override
  State<AnimatedAiIcon> createState() => _AnimatedAiIconState();
}

class _AnimatedAiIconState extends State<AnimatedAiIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(curve: Curves.easeInOut, parent: _c),
      ),
      child: const Icon(Icons.smart_toy, size: 26),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

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
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String title;
  final String date;
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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

class AnimatedActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final String hero;

  const AnimatedActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.hero,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(
            scale: scale,
            child: FloatingActionButton.extended(
              heroTag: widget.hero,
              backgroundColor: widget.color,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              icon: Icon(widget.icon),
              label: Text(widget.label),
              onPressed: widget.onPressed,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }
}
