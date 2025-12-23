import 'package:eatify/features/nav_bar/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/common/round_button.dart';
import '../../core/common/round_textfield.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 64),
            const Text(
              "Login",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              "Add your info to login",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 25),
            RoundTextfield(
              hintText: "Your Email",
              controller: txtEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 25),
            RoundTextfield(
              hintText: "Password",
              controller: txtPassword,
              obscureText: true,
            ),
            const SizedBox(height: 25),
            RoundButton(
              title: loading ? "Loading..." : "Login",
              onPressed: loading ? null : _handleLogin,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ResetPasswordScreen()),
                );
              },
              child: const Text("Forgot your password?"),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    final authController = ref.read(authControllerProvider);

    // Basic validation
    if (!txtEmail.text.contains("@")) {
      showAlert("Enter a valid email");
      return;
    }
    if (txtPassword.text.length < 6) {
      showAlert("Password must be at least 6 characters");
      return;
    }

    setState(() => loading = true);

    try {
      // Await the signIn call; no return value needed
      await authController.signIn(
        email: txtEmail.text.trim(),
        password: txtPassword.text.trim(),
      );

      // Navigate to MainTabView after successful login
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NavBar()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAlert("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showAlert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eatify"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
