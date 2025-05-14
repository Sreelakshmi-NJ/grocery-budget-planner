import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Text field controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Flags for password visibility and loading state
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Email/Password Login Method with role check
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['role'] != null) {
          final role = data['role'] as String;
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin-home');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User role not found or is invalid.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Google Sign-In Logic
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? existingUser =
          await GoogleSignIn().signInSilently();
      if (existingUser != null) {
        await _handleGoogleSignInAccount(existingUser);
        return;
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      await _handleGoogleSignInAccount(googleUser);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: $e')),
      );
    }
  }

  Future<void> _handleGoogleSignInAccount(
      GoogleSignInAccount googleUser) async {
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      final user = userCredential.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? 'No Name',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'role': 'user',
      });
    }
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  /// Forgot Password: Sends a password reset email
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email to reset your password."),
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent. Check your inbox."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top Navigation Bar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal[700],
        title: const Text(
          "Grocery Budget Planner",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          _NavItem(
            title: "Features",
            onTap: () => Navigator.pushNamed(context, "/features"),
          ),
          /*_NavItem(
            title: "How It Works",
            onTap: () => Navigator.pushNamed(context, "/how_it_works"),
          ),*/
          _NavItem(
            title: "About",
            onTap: () => Navigator.pushNamed(context, "/about"),
          ),
          _NavItem(
            title: "Sign Up",
            onTap: () => Navigator.pushNamed(context, "/signup"),
          ),
        ],
      ),
      // Body with Background Image and Semi-transparent Overlay
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/budget.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        // Using a Stack so we can place the login form & the small footer together
        child: Stack(
          children: [
            // Dark overlay
            Container(color: Colors.black.withOpacity(0.5)),
            // Main scrollable content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Login Form Section (increased vertical padding)
                  Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(190), // ~75% opacity
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // Increased the form container padding
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 30,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  fontSize: 28, // increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              /*ElevatedButton.icon(
                                onPressed: _loginWithGoogle,
                                icon: Image.asset(
                                  'assets/google_logo.png',
                                  height: 18,
                                  width: 18,
                                ),
                                label: const Text(
                                  "Google Sign-In",
                                  style: TextStyle(color: Colors.black87),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                ),
                              ),*/
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _forgotPassword,
                                child: const Text("Forgot Password?"),
                              ),
                              const SizedBox(height: 20),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 50,
                                        ),
                                      ),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, "/signup"),
                                child: const Text(
                                    "Don't have an account? Sign Up"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Small Footer
                  Container(
                    color: Colors.teal[800],
                    width: double.infinity,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Padding(
                          padding: const EdgeInsets.all(10), // Reduced padding
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                spacing: 16, // Reduced spacing
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _FooterItem(
                                    title: "Features",
                                    onTap: () => Navigator.pushNamed(
                                        context, "/features"),
                                  ),
                                  /*_FooterItem(
                                    title: "How It Works",
                                    onTap: () => Navigator.pushNamed(
                                        context, "/how_it_works"),
                                  ),*/
                                  _FooterItem(
                                    title: "About",
                                    onTap: () =>
                                        Navigator.pushNamed(context, "/about"),
                                  ),
                                  _FooterItem(
                                    title: "Sign Up",
                                    onTap: () =>
                                        Navigator.pushNamed(context, "/signup"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Connect With Us",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Email: support@groceryplanner.com  |  Phone: +1 234 567 890",
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Location: 123 Grocery Street, Food City, USA",
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.facebook,
                                        color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.instagram,
                                        color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.twitter,
                                        color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "© 2025 Grocery Budget Planner. All Rights Reserved.",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12),
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
          ],
        ),
      ),
    );
  }
}

// NAVIGATION ITEM (for top menu)
class _NavItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _NavItem({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}

// FOOTER ITEM (for footer links)
class _FooterItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _FooterItem({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
