import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminBudgetMonitoringScreen extends StatefulWidget {
  const AdminBudgetMonitoringScreen({super.key});

  @override
  State<AdminBudgetMonitoringScreen> createState() =>
      _AdminBudgetMonitoringScreenState();
}

class _AdminBudgetMonitoringScreenState
    extends State<AdminBudgetMonitoringScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  Future<List<Map<String, dynamic>>> _fetchUserBudgets() async {
    List<Map<String, dynamic>> userBudgets = [];

    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // For each user, get their budget and expenses for selected month
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Get user's budget for selected month
        final budgetDoc = await _firestore
            .collection('budgets')
            .doc(userId)
            .collection('monthlyBudgets')
            .doc(_selectedMonth)
            .get();

        // Get user's expenses for selected month
        final expensesSnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: userId)
            .where('monthKey', isEqualTo: _selectedMonth)
            .get();

        double totalExpenses = 0;
        for (var expense in expensesSnapshot.docs) {
          totalExpenses += (expense.data()['amount'] as num).toDouble();
        }

        double monthlyBudget = 0;
        if (budgetDoc.exists) {
          final budgetData = budgetDoc.data();
          if (budgetData != null) {
            monthlyBudget = (budgetData['monthlyBudget'] as num).toDouble();
          }
        }

        userBudgets.add({
          'userId': userId,
          'name': userData['name'] ?? 'Unknown User',
          'email': userData['email'] ?? 'No Email',
          'monthlyBudget': monthlyBudget,
          'totalExpenses': totalExpenses,
          'remainingBudget': monthlyBudget - totalExpenses,
          'budgetUtilization':
              monthlyBudget > 0 ? (totalExpenses / monthlyBudget) * 100 : 0,
        });
      }

      // Sort by budget utilization (highest first)
      userBudgets.sort((a, b) =>
          (b['budgetUtilization'] as double)
              .compareTo(a['budgetUtilization'] as double));

      return userBudgets;
    } catch (e) {
      print('Error fetching user budgets: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Monitoring'),
        backgroundColor: Colors.teal[700],
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Select Month: ',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedMonth,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedMonth = newValue);
                    }
                  },
                  items: [
                    '2025-03',
                    '2025-04',
                    '2025-05',
                    '2025-06',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Budget list
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUserBudgets(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userBudgets = snapshot.data!;
                if (userBudgets.isEmpty) {
                  return const Center(
                      child: Text('No budget data available for this month'));
                }

                return ListView.builder(
                  itemCount: userBudgets.length,
                  itemBuilder: (context, index) {
                    final budget = userBudgets[index];
                    final utilization = budget['budgetUtilization'] as double;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        budget['email'],
                                        style:
                                            const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildUtilizationBadge(utilization),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: utilization / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                utilization > 100
                                    ? Colors.red
                                    : utilization > 80
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Budget: ₹${budget['monthlyBudget'].toStringAsFixed(2)}'),
                                Text(
                                    'Spent: ₹${budget['totalExpenses'].toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                'Remaining: ₹${budget['remainingBudget'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: budget['remainingBudget'] < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationBadge(double utilization) {
    Color backgroundColor;
    String text;

    if (utilization > 100) {
      backgroundColor = Colors.red;
      text = 'Over Budget';
    } else if (utilization > 80) {
      backgroundColor = Colors.orange;
      text = 'Warning';
    } else {
      backgroundColor = Colors.green;
      text = 'On Track';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 