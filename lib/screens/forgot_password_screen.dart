import 'package:flutter/material.dart';
import 'user_store.dart'; // Make sure this file exists and contains UserStore

class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({super.key, required this.email});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF140536).withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            // Top logo
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/background.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Update Password",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 30),

                        // NEW PASSWORD
                        textField(
                          "New Password",
                          passwordController,
                          obscure: !isPasswordVisible,
                          toggleVisibility: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          isVisible: isPasswordVisible,
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return "Minimum 6 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // CONFIRM PASSWORD
                        textField(
                          "Confirm Password",
                          confirmController,
                          obscure: !isConfirmVisible,
                          toggleVisibility: () {
                            setState(() {
                              isConfirmVisible = !isConfirmVisible;
                            });
                          },
                          isVisible: isConfirmVisible,
                          validator: (v) {
                            if (v != passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 30),

                        // UPDATE BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5F27CD),
                              minimumSize: Size(double.infinity, 50)),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // ✅ Update password using UserStore
                              await UserStore.addUser(
                                  widget.email, passwordController.text);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Password updated successfully")),
                              );
                              Navigator.pop(context); // go back to login
                            }
                          },
                          child: Text(
                            "Update",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textField(String hint, TextEditingController controller,
      {bool obscure = false,
      VoidCallback? toggleVisibility,
      bool isVisible = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Color(0xFF1F1B3B),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
    );
  }
}
