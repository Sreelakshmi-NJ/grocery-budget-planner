import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _adminLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate the user
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user has admin privileges (based on Firestore data)
      if (userCredential.user != null) {
        // Get the user's document from Firestore to check their role
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          // Ensure role field exists and is valid
          if (userDoc['role'] != null && userDoc['role'] == 'admin') {
            // Navigate to Admin Home if the role is 'admin'
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/admin-home');
          } else {
            // Handle case where user is not an admin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('You are not authorized as an admin.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User role not found.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuthException errors
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else {
        errorMessage = 'An error occurred: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // Handle any other types of errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _adminLogin, // Disable button while loading
                    child: const Text('Login as Admin'),
                  ),
          ],
        ),
      ),
    );
  }
}
