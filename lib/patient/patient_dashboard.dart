import 'package:care_nexus/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Your Project Imports
import 'package:care_nexus/patient/profilepage.dart' hide ProfilePage;
import 'package:care_nexus/profile/profile_page.dart';
import 'package:care_nexus/widgets/dashboard_circle_item.dart';
import 'package:care_nexus/services/permission_service.dart';
import 'package:care_nexus/widgets/sos_button.dart';
import 'package:care_nexus/lib/core/url_helper.dart';

// Pages
import '../auth/login_page.dart';
import '../chats/chatpage.dart';
import 'appointments_page.dart';
import 'health_records_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .snapshots();

    // Request permissions once on dashboard entry
    PermissionService.requestAllPermissions();
  }

  /// Fixed Google Maps URL logic
  Future<void> openNearby(String place) async {
    final String query = Uri.encodeComponent('$place near me');
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch maps: $e");
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern soft grey
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "CareNexus",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: const SosButton(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String name = userData?['name'] ?? "User";
          final String email = userData?['email'] ?? user?.email ?? "";

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(name, email),
                        const SizedBox(height: 30),
                        const _SectionHeader(title: "Emergency Services"),
                        const SizedBox(height: 15),
                        _buildHorizontalServices(),
                        const SizedBox(height: 35),
                        const _SectionHeader(title: "Quick Actions"),
                        const SizedBox(height: 15),
                        _buildQuickActionsGrid(userData),
                        // const SizedBox(height: 35),
                        // const _SectionHeader(title: "Government Portals"),
                        const SizedBox(height: 15),
                        _buildHealthSchemes(),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalServices() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _serviceCard(
            "Hospitals",
            Icons.local_hospital,
            Colors.red,
            "hospital",
          ),
          _serviceCard(
            "Ambulance",
            Icons.airport_shuttle,
            Colors.orange,
            "ambulance",
          ),
          _serviceCard("Pharmacy", Icons.medication, Colors.green, "pharmacy"),
          _serviceCard("Labs", Icons.biotech, Colors.purple, "pathology lab"),
        ],
      ),
    );
  }

  Widget _serviceCard(String label, IconData icon, Color color, String query) {
    return GestureDetector(
      onTap: () => openNearby(query),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(Map<String, dynamic>? userData) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _actionCard(
          "Doctor Chat",
          "Consult with experts",
          Icons.chat_bubble_rounded,
          const Color(0xFF2563EB),
          () => _navigateToChat('doctor_001'),
        ),
        _actionCard(
          "AI Assistant",
          "Instant medical info",
          Icons.smart_toy_rounded,
          const Color(0xFF4E8E9E),
          () => _navigateToChat('AI_BOT'),
        ),
      ],
    );
  }

  Widget _actionCard(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSchemes() {
    final List<Map<String, dynamic>> healthSchemes = [
      {
        'title': 'Ayushman Bharat (PM-JAY)',
        'desc':
            'World\'s largest health insurance scheme providing ₹5 Lakh cover.',
        'icon': Icons.security_rounded,
        'color': const Color(0xFFE67E22),
        'url': 'https://dashboard.pmjay.gov.in/',
      },
      {
        'title': 'National Health Mission (NHM)',
        'desc':
            'Support for universal access to equitable and affordable healthcare.',
        'icon': Icons.location_city_rounded,
        'color': const Color(0xFF2E86C1),
        'url': 'https://nhm.gov.in/',
      },
      {
        'title': 'Janani Suraksha Yojana (JSY)',
        'desc':
            'Safe motherhood intervention providing cash assistance for delivery.',
        'icon': Icons.pregnant_woman_rounded,
        'color': const Color(0xFFD81B60),
        'url':
            'https://nhm.gov.in/index1.php?lang=1&level=3&sublinkid=841&lid=309',
      },
      {
        'title': 'Rashtriya Bal Swasthya (RBSK)',
        'desc': 'Child health screening and early intervention services.',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFF27AE60),
        'url': 'https://rbsk.nhm.gov.in/',
      },
      {
        'title': 'PMJAY – Urban',
        'desc':
            'Health insurance coverage specifically tailored for urban poor.',
        'icon': Icons.apartment_rounded,
        'color': const Color(0xFFF39C12),
        'url': 'https://pmjay.gov.in/about/pmjay',
      },
      {
        'title': 'Central Govt Health Scheme (CGHS)',
        'desc':
            'Comprehensive medical facilities for central government employees.',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF8E44AD),
        'url': 'https://cghs.nic.in/',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "National Health Schemes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: healthSchemes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final scheme = healthSchemes[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme['color'].withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(scheme['icon'], color: scheme['color'], size: 26),
                ),
                title: Text(
                  scheme['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    scheme['desc'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade600,
                      height: 1.3,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
                onTap: () => UrlHelper.openWeb(scheme['url']),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1E3A8A)),
            child: Center(
              child: Text(
                "Menu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _drawerTile("Profile", Icons.person_outline, const ProfilePage()),
          _drawerTile(
            "Appointments",
            Icons.calendar_today_outlined,
            const AppointmentsPage(),
          ),
          _drawerTile(
            "Medical Records",
            Icons.folder_open_outlined,
            const HealthRecordsPage(),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Version 1.0.4",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _drawerTile(String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  void _navigateToChat(String receiverId) {
    if (user == null) return;
    final String chatId = receiverId == "AI_BOT"
        ? "ai_chat_${user!.uid}"
        : (user!.uid.compareTo(receiverId) < 0
              ? "${user!.uid}_$receiverId"
              : "${receiverId}_${user!.uid}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          senderId: user!.uid,
          receiverId: receiverId,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }
}
