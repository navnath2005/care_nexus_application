import 'package:care_nexus/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'routes.dart' show RoleRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const CareNexus());
}

Widget authBackground({required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: child),
  );
}

/* ******************** APP ROOT ******************** */
class Dashboard extends StatelessWidget {
  final String title;

  const Dashboard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 22))),
    );
  }
}

class CareNexus extends StatelessWidget {
  const CareNexus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Care Nexus",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashPage();
          }

          return snapshot.data == null ? const LoginPage() : const RoleRouter();
        },
      ),
    );
  }
}

bool _googleSigningIn = false;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool loading = false;

  // 🔐 LOGIN
  Future<void> login() async {
    if (!_form.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Welcome back 👋")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  bool _isPasswordVisible = false;

  // 🔵 GOOGLE LOGIN
  Future<void> signInGoogle() async {
    if (_googleSigningIn) return; // 🔥 BLOCK DOUBLE CALL
    _googleSigningIn = true;

    try {
      final gUser = await GoogleSignIn().signIn();

      if (gUser == null) return;

      final gAuth = await gUser.authentication;

      final cred = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
        accessToken: gAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _googleSigningIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: authBackground(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Care Nexus",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) =>
                          v != null && v.contains("@") ? null : "Invalid email",
                    ),

                    const SizedBox(height: 12),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: password,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : "Min 6 characters",
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                setState(() => loading = true);
                                try {
                                  await signInGoogle();
                                } finally {
                                  if (mounted) setState(() => loading = false);
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/google.jpg", height: 22),
                            const SizedBox(width: 12),
                            const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      child: const Text("Create new account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  String role = "Patient";
  final roles = ["Doctor", "Patient", "Ambulance", "Medical"];

  Future register() async {
    setState(() => loading = true);

    try {
      final u = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(u.user!.uid)
          .set({
            "name": name.text.trim(),
            "email": email.text.trim(),
            "role": role,
            "createdAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Account created 🎉")));

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: "Full Name"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: "Register As"),
                    items: roles
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => role = v!),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : register,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text("Register"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  bool loading = false;

  Future reset() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reset link sent 📩")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : reset,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data()!;

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name: ${data["name"]}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Email: ${data["email"]}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Role: ${data["role"]}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
