import 'package:eatify/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/common/round_button.dart';
import '../../core/common/round_textfield.dart';
import '../../providers/auth_provider.dart';

final loadingProvider = StateProvider<bool>((ref) => false);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Add your info to sign up",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 25),
                RoundTextfield(hintText: "Full Name", controller: txtName),
                const SizedBox(height: 25),
                RoundTextfield(
                  hintText: "Email",
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
                RoundTextfield(
                  hintText: "Confirm Password",
                  controller: txtConfirmPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                RoundButton(
                  title: isLoading ? "Loading..." : "Sign Up",
                  onPressed: isLoading ? null : _handleSignUp,
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _handleSignUp() async {
    final authController = ref.read(authControllerProvider);
    final name = txtName.text.trim();
    final email = txtEmail.text.trim();
    final password = txtPassword.text;
    final confirmPassword = txtConfirmPassword.text;

    // Validation
    if (name.isEmpty) return _showAlert("Please enter your name");
    if (!email.contains("@")) return _showAlert("Enter a valid email");
    if (password.length < 6) return _showAlert("Password must be at least 6 characters");
    if (password != confirmPassword) return _showAlert("Passwords do not match");

    ref.read(loadingProvider.notifier).state = true;

    try {
      await authController.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      ref.read(loadingProvider.notifier).state = false;

      if (!mounted) return;
      _showAlert(
        "Account created successfully! Please login.",
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      );
    } catch (e) {
      ref.read(loadingProvider.notifier).state = false;
      _showAlert("Signup failed: ${e.toString()}");
    }
  }

  void _showAlert(String msg, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eatify"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
