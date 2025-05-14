import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting month keys

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate current month key (e.g., "2025-04")
  String get currentMonthKey => DateFormat('yyyy-MM').format(DateTime.now());

  /// Saves or updates the monthly budget for the current month.
  Future<void> _saveBudget() async {
    final double? newBudget = double.tryParse(_budgetController.text.trim());
    if (newBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number.")),
      );
      return;
    }

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user logged in.")),
        );
        return;
      }
      // Reference to current month’s budget document under budgets/user.uid/monthlyBudgets/currentMonthKey.
      final DocumentReference monthBudgetRef = _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('monthlyBudgets')
          .doc(currentMonthKey);

      await monthBudgetRef.set({
        'monthlyBudget': newBudget,
        'currentSpent': FieldValue.increment(
            0), // No spending yet, or leave unchanged on update.
        'updatedAt': FieldValue.serverTimestamp(),
        'monthKey': currentMonthKey,
        'isActive': true,
      }, SetOptions(merge: true));
      _budgetController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget Updated!")),
      );
    } catch (e) {
      debugPrint("Error saving budget: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving budget: $e")),
      );
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery Budget Planner"),
        backgroundColor: Colors.teal.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image with updated method for opacity.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/budget.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildBudgetCard(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hero Section
  Widget _buildHeroSection() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Stay on top of your grocery budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Easily manage your monthly spending, track expenses, and save more on groceries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Budget Card with Firestore Data and Remaining Budget
  Widget _buildBudgetCard(User user) {
    final DocumentReference currentBudgetRef = _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('monthlyBudgets')
        .doc(currentMonthKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Card(
        elevation: 8.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        // Use a non-const color because of the fromRGBO call.
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: currentBudgetRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set Your Monthly Budget for $currentMonthKey",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Budget',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        await _saveBudget();
                      },
                      child: const Text("Save Budget"),
                    ),
                  ],
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final double monthlyBudget =
                  ((data['monthlyBudget'] ?? 0) as num).toDouble();
              final double currentSpent =
                  ((data['currentSpent'] ?? 0) as num).toDouble();
              final double remainingBudget = monthlyBudget - currentSpent;
              final double progress = monthlyBudget > 0
                  ? (currentSpent / monthlyBudget).clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monthly Budget for $currentMonthKey",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Monthly Budget: ₹${monthlyBudget.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Current Spent: ₹${currentSpent.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Remaining Budget: ₹${remainingBudget.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: progress >= 1.0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 24.0),
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Monthly Budget',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveBudget();
                    },
                    child: const Text("Update Budget"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
