import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
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
          "AI Chat",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: userFuture,
              builder: (context, snapshot) {
                final name =
                    snapshot.data?['name'] ?? user?.displayName ?? "User";
                final photoUrl = user?.photoURL;
                final initial = (name.isNotEmpty)
                    ? name[0].toUpperCase()
                    : (user?.email?.isNotEmpty == true
                        ? user!.email![0].toUpperCase()
                        : 'U');
                return DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: Colors.blue.shade700,
                        child: photoUrl == null
                            ? Text(initial,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Chat History"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text("AI Chat Page"),
      ),
    );
  }
}
