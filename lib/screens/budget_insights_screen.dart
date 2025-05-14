import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Data model representing a month and its total spending.
class BudgetInsight {
  final String month;
  final double spending;
  BudgetInsight(this.month, this.spending);
}

class BudgetInsightsScreen extends StatefulWidget {
  const BudgetInsightsScreen({super.key});

  @override
  State<BudgetInsightsScreen> createState() => _BudgetInsightsScreenState();
}

class _BudgetInsightsScreenState extends State<BudgetInsightsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<MonthlyBudgetData> _monthlyData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTimeframe = '3M'; // Default to 3 months

  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
  }

  Future<void> _fetchBudgetData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Get current month's budget
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final budgetDoc = await _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('monthlyBudgets')
          .doc(currentMonth)
          .get();

      // Get expenses for the current month
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('monthKey', isEqualTo: currentMonth)
          .get();

      // Calculate total spent
      final totalSpent = expensesSnapshot.docs.fold<double>(
        0,
        (total, doc) => total + (doc.data()['amount'] ?? 0).toDouble(),
      );

      // Get historical data
      final historicalData = await _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('monthlyBudgets')
          .orderBy('monthKey', descending: true)
          .limit(12)
          .get();

      // Use a map to ensure unique entries per month
      Map<String, MonthlyBudgetData> monthlyDataMap = {};
      
      // Add current month if it exists
      if (budgetDoc.exists) {
        final budget = (budgetDoc.data()!['monthlyBudget'] ?? 0).toDouble();
        monthlyDataMap[currentMonth] = MonthlyBudgetData(
          month: currentMonth,
          budget: budget,
          spent: totalSpent,
          saved: budget - totalSpent,
        );
      }

      // Add historical data, ensuring no duplicates
      for (var doc in historicalData.docs) {
        final data = doc.data();
        final month = data['monthKey'] as String;
        // Skip if we already have data for this month
        if (!monthlyDataMap.containsKey(month)) {
          final budget = (data['monthlyBudget'] ?? 0).toDouble();
          final spent = (data['currentSpent'] ?? 0).toDouble();
          monthlyDataMap[month] = MonthlyBudgetData(
            month: month,
            budget: budget,
            spent: spent,
            saved: budget - spent,
          );
        }
      }

      // Convert map to sorted list
      List<MonthlyBudgetData> tempData = monthlyDataMap.values.toList()
        ..sort((a, b) => b.month.compareTo(a.month)); // Sort by month descending

      if (!mounted) return;
      setState(() {
        _monthlyData = tempData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<MonthlyBudgetData> _getFilteredData() {
    int monthsToShow;
    switch (_selectedTimeframe) {
      case '1M':
        monthsToShow = 1;
        break;
      case '3M':
        monthsToShow = 3;
        break;
      case '6M':
        monthsToShow = 6;
        break;
      case '12M':
        monthsToShow = 12;
        break;
      default:
        monthsToShow = 3;
    }
    return _monthlyData.take(monthsToShow).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text("Error: $_errorMessage")),
      );
    }

    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No budget data available.")),
      );
    }

    final currentMonth = filteredData.first;
    final totalBudget = currentMonth.budget;
    final totalSpent = currentMonth.spent;
    final remainingBudget = currentMonth.saved;
    final spendingPercentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    // Calculate savings insights
    final averageMonthlySpending = filteredData.fold<double>(
      0,
      (sum, data) => sum + data.spent,
    ) / filteredData.length;
    
    final savingsRate = totalBudget > 0 
        ? ((totalBudget - totalSpent) / totalBudget * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Insights"),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Selector
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeframeButton('1M'),
                      _buildTimeframeButton('3M'),
                      _buildTimeframeButton('6M'),
                      _buildTimeframeButton('12M'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Month Overview
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700, Colors.teal.shade900],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Month Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBudgetInfo(
                            'Budget',
                            '₹${totalBudget.toStringAsFixed(0)}',
                            Colors.white,
                          ),
                          _buildBudgetInfo(
                            'Spent',
                            '₹${totalSpent.toStringAsFixed(0)}',
                            Colors.white,
                          ),
                          _buildBudgetInfo(
                            'Remaining',
                            '₹${remainingBudget.toStringAsFixed(0)}',
                            remainingBudget >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: spendingPercentage.toDouble(),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spendingPercentage > 0.8
                                ? Colors.red
                                : spendingPercentage > 0.5
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(spendingPercentage * 100).toStringAsFixed(1)}% of budget used',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Insights
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInsightCard(
                            'Average Monthly Spending',
                            '₹${averageMonthlySpending.toStringAsFixed(0)}',
                            Icons.trending_up,
                            Colors.blue,
                          ),
                          _buildInsightCard(
                            'Best Month',
                            '₹${filteredData.map((e) => e.saved).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}',
                            Icons.star,
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monthly Trends Chart
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Trends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: filteredData
                                .map((e) => e.budget)
                                .reduce((a, b) => a > b ? a : b),
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= filteredData.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        DateFormat('MMM')
                                            .format(DateFormat('yyyy-MM')
                                                .parse(filteredData[index].month)),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(filteredData.length, (index) {
                              final data = filteredData[index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.budget,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.teal[300],
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: data.budget,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: data.spent,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    color: data.spent > data.budget
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monthly Breakdown
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Breakdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final data = filteredData[index];
                          final month = DateFormat('MMMM yyyy')
                              .format(DateFormat('yyyy-MM').parse(data.month));
                          final isOverBudget = data.spent > data.budget;
                          final monthlySavingsRate = data.budget > 0
                              ? ((data.budget - data.spent) / data.budget * 100)
                                  .clamp(0.0, 100.0)
                              : 0.0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(month),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget: ₹${data.budget.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Spent: ₹${data.spent.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isOverBudget ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Savings Rate: ${monthlySavingsRate.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: monthlySavingsRate > 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${data.saved.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: data.saved >= 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    data.saved >= 0 ? 'Saved' : 'Over',
                                    style: TextStyle(
                                      color: data.saved >= 0 ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String timeframe) {
    final isSelected = _selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = timeframe;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          timeframe,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyBudgetData {
  final String month;
  final double budget;
  final double spent;
  final double saved;

  MonthlyBudgetData({
    required this.month,
    required this.budget,
    required this.spent,
    required this.saved,
  });
}
