import 'package:flutter/material.dart';
import 'user_store.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;

  // =========================
  // SIGNUP API CALL
  // =========================
  Future signupUser(String email, String password) async {
    try {
      final success = await UserStore.addUser(email, password);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created! Check your email to verify."),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signup failed. Email may already be registered."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup error. Check your connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF140536).withValues(alpha: 0.85),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 30),

                // EMAIL
                TextFormField(
                  controller: emailController,
                  style: TextStyle(color: Colors.white),
                  decoration: input("Email"),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter email";
                    final gmailRegex =
                        RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
                    if (!gmailRegex.hasMatch(v.trim())) {
                      return "Use valid @gmail.com";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  style: TextStyle(color: Colors.white),
                  decoration: input("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return "Min 6 characters";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: confirmController,
                  obscureText: !isConfirmVisible,
                  style: TextStyle(color: Colors.white),
                  decoration: input("Confirm Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmVisible = !isConfirmVisible;
                        });
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                // SIGNUP BUTTON
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5F27CD),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String email =
                          emailController.text.trim().toLowerCase();
                      String password = passwordController.text;

                      print("SIGNUP EMAIL: $email");
                      print("SIGNUP PASSWORD: $password");

                      await signupUser(email, password);
                    }
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Color(0xFF1F1B3B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}