import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isItemizedMode = true;
  bool isLoading = false;
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  String get currentMonthKey => DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _saveExpense() async {
    final double? amount = double.tryParse(amountController.text.trim());
    final String category = categoryController.text.trim();
    final String description = descriptionController.text.trim();

    if (amount == null || category.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields properly.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      await _firestore.collection('expenses').add({
        'userId': user.uid,
        'amount': amount,
        'category': category,
        'description': description,
        'monthKey': selectedMonth,
        'createdAt': FieldValue.serverTimestamp(),
        'isItemized': isItemizedMode,
        'date': DateTime.now(),
      });

      final DocumentReference budgetRef = _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('monthlyBudgets')
          .doc(selectedMonth);

      await budgetRef.set({
        'currentSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully!')),
      );

      amountController.clear();
      categoryController.clear();
      descriptionController.clear();
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving expense: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted!')),
      );
    } catch (e) {
      debugPrint("Error deleting: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: $e')),
      );
    }
  }

  Future<void> _deleteAllExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final query = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('monthKey', isEqualTo: selectedMonth)
          .get();

      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All expenses deleted!')),
      );
    } catch (e) {
      debugPrint("Error deleting: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expenses: $e')),
      );
    }
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Itemized Entry"),
                  selected: isItemizedMode,
                  onSelected: (_) => setState(() => isItemizedMode = true),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Total Bill"),
                  selected: !isItemizedMode,
                  onSelected: (_) => setState(() => isItemizedMode = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveExpense,
                    child: const Text('Save Expense'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(User user) {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedMonth,
          onChanged: (newMonth) {
            setState(() {
              selectedMonth = newMonth!;
            });
          },
          items: [
            '2025-03',
            '2025-04',
            '2025-05',
            '2025-06',
            // Add other months here
          ]
              .map<DropdownMenuItem<String>>(
                  (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
              .toList(),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('expenses')
              .where('userId', isEqualTo: user.uid)
              .where('monthKey', isEqualTo: selectedMonth)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text("Error: ${snapshot.error}");
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No expenses recorded for this month."),
              );
            }

            return Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _deleteAllExpenses,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete All"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    final amount = data['amount'] ?? 0;
                    final category = data['category'] ?? '';
                    final description = data['description'] ?? '';
                    final expenseId = snapshot.data!.docs[index].id;
                    final Timestamp? ts = data['createdAt'];
                    final time = ts != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        title:
                            Text("₹${amount.toStringAsFixed(2)} - $category"),
                        subtitle: Text("$description\n$time"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Are you sure?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      _deleteExpense(expenseId);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Yes"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("No"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/exbg.jpg'), // your bg image
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.teal,
              title: const Text(
                "Grocery Budget Planner",
                style: TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Track Expenses",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Expanded(
              child: user == null
                  ? const Center(
                      child: Text("Please log in to track expenses."))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildForm(),
                          const SizedBox(height: 10),
                          const Text(
                            "This Month's Expenses",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _buildExpenseList(user),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
