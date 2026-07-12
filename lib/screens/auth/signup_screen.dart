import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _signUp() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool hasError = false;

    // Validation
    if (name.isEmpty) {
      setState(() => _nameError = "Full Name is required");
      hasError = true;
    }

    if (email.isEmpty) {
      setState(() => _emailError = "Email is required");
      hasError = true;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = "Please enter a valid email address");
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = "Password is required");
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = "Password must be at least 6 characters");
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = "Confirm your password");
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update Auth Profile Name
        user.updateDisplayName(name).then((_) => user.reload()).catchError((e) {
          debugPrint("Profile Update Error: $e");
        });

        // Save User Data to Firestore
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }).catchError((e) {
          debugPrint("Firestore Data Sync Error: $e");
        });

        if (mounted) {
          // 3. Navigate immediately to Home
          // We pass the name directly to HomeScreen so it shows up instantly
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(displayName: name),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'weak-password') {
            _passwordError = 'The password provided is too weak.';
          } else if (e.code == 'email-already-in-use') {
            _emailError = 'The account already exists for that email.';
          } else if (e.code == 'invalid-email') {
            _emailError = 'The email address is badly formatted.';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? "An error occurred")),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Signup Error: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 80,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Join us and start comparing medicine prices.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              CustomTextField(
                controller: _nameController,
                hintText: "Full Name",
                icon: Icons.person_outline_rounded,
                errorText: _nameError,
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
                errorText: _emailError,
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                errorText: _passwordError,
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                errorText: _confirmPasswordError,
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.secondary))
                  : CustomButton(
                      text: "Sign Up",
                      color: AppColors.secondary,
                      onPressed: _signUp,
                    ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
