import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Normal Sign Up with Email & Password
  Future<void> _signUp() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Google Sign Up logic
  Future<void> _signUpWithGoogle() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TOP NAVBAR
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
            title: "Login",
            onTap: () => Navigator.pushNamed(context, "/login"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/signup"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal[700],
              ),
              child: const Text("Sign Up"),
            ),
          ),
        ],
      ),

      // BODY: Background image with a scrollable column for form and footer
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/signupbg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SIGN-UP FORM SECTION
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(190), // ~75% opacity
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                              ),
                              TextField(
                                controller: _emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                    labelText: 'Phone Number'),
                                keyboardType: TextInputType.phone,
                              ),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(_isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              /*Align(
                                alignment: Alignment.center,
                                child: ElevatedButton.icon(
                                  onPressed: _signUpWithGoogle,
                                  icon: Image.asset(
                                    'assets/google_logo.png',
                                    height: 18,
                                    width: 18,
                                  ),
                                  label: const Text(
                                    "Google Sign-Up",
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),*/
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 40,
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // FOOTER SECTION
              Container(
                color: Colors.teal[800],
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 30,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _FooterItem(
                                title: "Features",
                                onTap: () =>
                                    Navigator.pushNamed(context, "/features"),
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
                                title: "Login",
                                onTap: () =>
                                    Navigator.pushNamed(context, "/login"),
                              ),
                              _FooterItem(
                                title: "Sign Up",
                                onTap: () =>
                                    Navigator.pushNamed(context, "/signup"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Connect With Us",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Email: support@groceryplanner.com  |  Phone: +1 234 567 890",
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Location: 123 Grocery Street, Food City, USA",
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          const Text(
                            "© 2025 Grocery Budget Planner. All Rights Reserved.",
                            style: TextStyle(color: Colors.white54),
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
      ),
    );
  }
}

// NAVIGATION ITEM
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

// FOOTER LINK ITEM
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
