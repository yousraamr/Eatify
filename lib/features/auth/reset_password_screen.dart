import 'package:eatify/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/common/round_button.dart';
import '../../core/common/round_textfield.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController txtEmail = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Enter your email address and we'll send you a link to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 60),
                RoundTextfield(
                  hintText: "Your Email",
                  controller: txtEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 30),
                RoundButton(
                  title: loading ? "Sending..." : "Send Reset Link",
                  onPressed: loading ? null : _sendResetEmail,
                ),
              ],
            ),
          ),
          if (loading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _sendResetEmail() async {
    final email = txtEmail.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showAlert("Please enter a valid email address.");
      return;
    }

    setState(() => loading = true);

    final authController = ref.read(authControllerProvider);

    try {
      await authController.resetPassword(email);

      if (!mounted) return;

      _showAlert(
        "Password reset link sent to $email.\n\nPlease check your email inbox (and spam folder) to reset your password.",
        onOk: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      _showAlert("Failed to send reset email. Please try again.");
    } finally {
      if (mounted) setState(() => loading = false);
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
