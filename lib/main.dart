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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const CareNexus());
}

/* ******************** APP ROOT ******************** */
class Dashboard extends StatelessWidget {
  final String title;

  const Dashboard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 22),
        ),
      ),
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset link sent 📩")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email")),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading ? null : reset,
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Send Reset Link"),
          )
        ]),
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
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snap.data!.data()!;

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${data["name"]}",
                    style: const TextStyle(fontSize: 18)),
                Text("Email: ${data["email"]}",
                    style: const TextStyle(fontSize: 18)),
                Text("Role: ${data["role"]}",
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool loading = false;

  Future<void> signInGoogle() async {
    try {
      final g = await GoogleSignIn().signIn();
      if (g == null) return;

      final auth = await g.authentication;

      final cred = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      final user = await FirebaseAuth.instance.signInWithCredential(cred);

      final doc =
          FirebaseFirestore.instance.collection("users").doc(user.user!.uid);

      if (!(await doc.get()).exists) {
        await doc.set({
          "name": user.user!.displayName,
          "email": user.user!.email,
          "role": "Patient",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      final u = FirebaseAuth.instance.currentUser;

      if (u != null && !u.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verify email before login 📩")),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signed in with Google 😎")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus(); // 🔥 FIX

    if (!_form.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Welcome back 👋")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Unable to login")),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Care Nexus Login")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (v) => v != null && v.contains("@")
                        ? null
                        : "Enter valid email",
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : "Min 6 characters",
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Login"),
                    ),
                  ),
                  TextButton(
                    child: const Text("Forgot password?"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage()),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                    label: const Text("Continue with Google"),
                    onPressed: loading ? null : signInGoogle,
                  ),
                  TextButton(
                    child: const Text("Create new account"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    ),
                  )
                ]),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created 🎉")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: "Full Name")),
                const SizedBox(height: 12),
                TextField(
                    controller: email,
                    decoration:
                        const InputDecoration(labelText: "Email Address")),
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
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
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
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
