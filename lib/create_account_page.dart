import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool showPassword = false;
  bool showConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Create Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // Logo
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.cyan.shade100,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  width: 70,
                  height: 70,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Join Chatrio",
              style: TextStyle(
                fontSize: 24,
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Create your account to start connecting",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Rounded card container with fields
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Full Name
                  buildTextField(
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.person_outline,
                    controller: nameController,
                  ),
                  const SizedBox(height: 15),

                  // Email
                  buildTextField(
                    label: "Email",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  buildPasswordField(
                    controller: passwordController,
                    label: "Password",
                    hint: "Create a password",
                    obscure: !showPassword,
                    onEyeTap: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  buildPasswordField(
                    controller: confirmController,
                    label: "Confirm Password",
                    hint: "Confirm your password",
                    obscure: !showConfirm,
                    onEyeTap: () {
                      setState(() {
                        showConfirm = !showConfirm;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Gradient Create Account Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF19c8d1)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add Signup Logic or API call
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Already have account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Go back to login/home
                  },
                  child: const Text(
                    "Sign in",
                    style: TextStyle(
                      color: Color(0xFF19c8d1),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onEyeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: InkWell(
              onTap: onEyeTap,
              child: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
