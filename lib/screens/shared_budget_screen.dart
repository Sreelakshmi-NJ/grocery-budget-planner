import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Generates a random join code of the specified [length].
String generateJoinCode(int length) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random rand = Random();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
      .join();
}

class SharedBudgetScreen extends StatefulWidget {
  const SharedBudgetScreen({super.key});

  @override
  State<SharedBudgetScreen> createState() => _SharedBudgetScreenState();
}

class _SharedBudgetScreenState extends State<SharedBudgetScreen> {
  final TextEditingController _budgetNameController = TextEditingController();
  final TextEditingController _totalBudgetController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final TextEditingController _expenseDescriptionController = TextEditingController();
  final TextEditingController _contributionAmountController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      _firestore = FirebaseFirestore.instance;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  /// Creates a new shared budget with a generated join code.
  Future<void> _createSharedBudget() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App is still initializing. Please try again.")),
      );
      return;
    }
    final String budgetName = _budgetNameController.text.trim();
    final String totalBudgetStr = _totalBudgetController.text.trim();

    if (budgetName.isEmpty || totalBudgetStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final double? totalBudget = double.tryParse(totalBudgetStr);
    if (totalBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid budget amount.")),
      );
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    try {
      final String joinCode = generateJoinCode(6);
      final DocumentReference budgetRef = await _firestore.collection("sharedBudgets").add({
        "budgetName": budgetName,
        "totalBudget": totalBudget,
        "currentAmount": 0.0, // Initial amount before contributions
        "spentAmount": 0.0,  // Track total spent
        "members": [user.uid],
        "joinCode": joinCode,
        "createdAt": FieldValue.serverTimestamp(),
        "creator": user.uid,
        "monthKey": DateFormat('yyyy-MM').format(DateTime.now()),
      });

      // Create initial contribution record
      await _firestore.collection("sharedBudgetContributions").add({
        "budgetId": budgetRef.id,
        "userId": user.uid,
        "amount": 0.0,
        "timestamp": FieldValue.serverTimestamp(),
      });

      _budgetNameController.clear();
      _totalBudgetController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shared budget created successfully. Join code: $joinCode")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating shared budget: $e")),
      );
    }
  }

  /// Add contribution to shared budget
  Future<void> _addContribution(String budgetId) async {
    final amount = double.tryParse(_contributionAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Add contribution record
      await _firestore.collection("sharedBudgetContributions").add({
        "budgetId": budgetId,
        "userId": user.uid,
        "amount": amount,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Update current amount in shared budget
      await _firestore.collection("sharedBudgets").doc(budgetId).update({
        "currentAmount": FieldValue.increment(amount),
      });

      _contributionAmountController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contribution added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding contribution: $e")),
      );
    }
  }

  /// Add expense to shared budget
  Future<void> _addExpense(String budgetId) async {
    final amount = double.tryParse(_expenseAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final description = _expenseDescriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description")),
      );
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get current budget document
      final budgetDoc = await _firestore.collection("sharedBudgets").doc(budgetId).get();
      final budgetData = budgetDoc.data() as Map<String, dynamic>;
      final currentAmount = (budgetData['currentAmount'] as num).toDouble();

      if (amount > currentAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense amount exceeds available budget")),
        );
        return;
      }

      // Add expense record
      await _firestore.collection("sharedExpenses").add({
        "budgetId": budgetId,
        "userId": user.uid,
        "amount": amount,
        "description": description,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Update spent amount in shared budget
      await _firestore.collection("sharedBudgets").doc(budgetId).update({
        "currentAmount": FieldValue.increment(-amount),
        "spentAmount": FieldValue.increment(amount),
      });

      _expenseAmountController.clear();
      _expenseDescriptionController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding expense: $e")),
      );
    }
  }

  /// Joins an existing shared budget using its join code
  Future<void> _joinSharedBudget(String joinCode) async {
    if (joinCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a join code")),
      );
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      // Find the budget with the given join code
      final QuerySnapshot budgetQuery = await _firestore
          .collection("sharedBudgets")
          .where("joinCode", isEqualTo: joinCode)
          .limit(1)
          .get();

      if (budgetQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid join code")),
        );
        return;
      }

      final DocumentReference budgetRef = budgetQuery.docs.first.reference;
      final budgetData = budgetQuery.docs.first.data() as Map<String, dynamic>;
      
      // Check if user is already a member
      final List<dynamic> members = budgetData['members'] ?? [];
      if (members.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are already a member of this budget")),
        );
        return;
      }

      // Add user to members list
      await budgetRef.update({
        "members": FieldValue.arrayUnion([user.uid])
      });

      // Create initial contribution record for the new member
      await _firestore.collection("sharedBudgetContributions").add({
        "budgetId": budgetRef.id,
        "userId": user.uid,
        "amount": 0.0,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully joined the shared budget")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error joining budget: $e")),
      );
    }
  }

  void _showAddExpenseDialog(String budgetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _expenseAmountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _expenseDescriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _addExpense(budgetId),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddContributionDialog(String budgetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Contribution"),
        content: TextField(
          controller: _contributionAmountController,
          decoration: const InputDecoration(labelText: "Amount"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _addContribution(budgetId),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Shows expense history for a shared budget
  void _showExpenseHistory(String budgetId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Expense History",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection("sharedExpenses")
                      .where("budgetId", isEqualTo: budgetId)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final expenses = snapshot.data!.docs;
                    if (expenses.isEmpty) {
                      return const Center(child: Text("No expenses yet"));
                    }
                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(expense['description'] ?? ''),
                          subtitle: Text(DateFormat('MMM dd, yyyy').format(
                              (expense['timestamp'] as Timestamp).toDate())),
                          trailing: Text(
                            "₹${expense['amount']?.toString() ?? '0'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows contribution history for a shared budget
  void _showContributionHistory(String budgetId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Contribution History",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection("sharedBudgetContributions")
                      .where("budgetId", isEqualTo: budgetId)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final contributions = snapshot.data!.docs;
                    if (contributions.isEmpty) {
                      return const Center(child: Text("No contributions yet"));
                    }
                    return ListView.builder(
                      itemCount: contributions.length,
                      itemBuilder: (context, index) {
                        final contribution =
                            contributions[index].data() as Map<String, dynamic>;
                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('users')
                              .doc(contribution['userId'])
                              .get(),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data?.get('name') ?? 'Unknown';
                            return ListTile(
                              title: Text(userName),
                              subtitle: Text(DateFormat('MMM dd, yyyy').format(
                                  (contribution['timestamp'] as Timestamp)
                                      .toDate())),
                              trailing: Text(
                                "₹${contribution['amount']?.toString() ?? '0'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetNameController.dispose();
    _totalBudgetController.dispose();
    _expenseAmountController.dispose();
    _expenseDescriptionController.dispose();
    _contributionAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view shared budgets.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Budgets"),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Create budget form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Create New Shared Budget",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _budgetNameController,
                      decoration: const InputDecoration(
                        labelText: "Budget Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalBudgetController,
                      decoration: const InputDecoration(
                        labelText: "Target Budget Amount",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createSharedBudget,
                      child: const Text("Create Shared Budget"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your Shared Budgets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // List of shared budgets
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("sharedBudgets")
                    .where("members", arrayContains: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final budgets = snapshot.data!.docs;
                  if (budgets.isEmpty) {
                    return const Center(child: Text("No shared budgets found"));
                  }
                  return ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index].data() as Map<String, dynamic>;
                      final budgetId = budgets[index].id;
                      final double totalBudget = (budget['totalBudget'] as num?)?.toDouble() ?? 0.0;
                      final double currentAmount = (budget['currentAmount'] as num?)?.toDouble() ?? 0.0;
                      final double spentAmount = (budget['spentAmount'] as num?)?.toDouble() ?? 0.0;
                      final bool isCreator = budget['creator'] == user.uid;

                      return Card(
                        child: ExpansionTile(
                          title: Text(budget['budgetName'] ?? 'Unnamed Budget'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Target: ₹$totalBudget"),
                              Text("Available: ₹$currentAmount"),
                              Text("Spent: ₹$spentAmount"),
                              if (isCreator)
                                Text("Join Code: ${budget['joinCode']}"),
                            ],
                          ),
                          children: [
                            ButtonBar(
                              alignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text("Contribute"),
                                  onPressed: () =>
                                      _showAddContributionDialog(budgetId),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.shopping_cart),
                                  label: const Text("Add Expense"),
                                  onPressed: () =>
                                      _showAddExpenseDialog(budgetId),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.history),
                                  label: const Text("History"),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("View History"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.payment),
                                              title: const Text("Contributions"),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showContributionHistory(budgetId);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.receipt),
                                              title: const Text("Expenses"),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showExpenseHistory(budgetId);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController joinCodeController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Join Shared Budget"),
              content: TextField(
                controller: joinCodeController,
                decoration: const InputDecoration(
                  labelText: "Enter Join Code",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => _joinSharedBudget(joinCodeController.text.trim()),
                  child: const Text("Join"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
