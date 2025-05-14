import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/error_dialog.dart';
import '../models/expense.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic> _analytics = {
    'totalUsers': 0,
    'activeUsers': 0,
    'totalExpenses': 0.0,
    'averageExpense': 0.0,
    'categoryTotals': <String, double>{},
    'weeklyTrends': <String, double>{},
    'budgetUtilization': 0.0,
    'overBudgetUsers': 0,
    'underBudgetUsers': 0,
    'mostUsedCategories': <String>[],
    'savingsAchieved': 0.0,
    'userEngagement': {
      'daily': 0,
      'weekly': 0,
      'monthly': 0,
    },
  };
  List<Map<String, dynamic>> _topSpenders = [];
  List<Map<String, dynamic>> _categoryWiseAnalysis = [];

  @override
  void initState() {
    super.initState();
    _verifyAdminStatus();
  }

  Future<void> _verifyAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please sign in to access admin features';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        setState(() {
          _error = 'You do not have admin privileges';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isAdmin = true;
      });
      await _fetchAnalytics();
    } catch (e) {
      setState(() {
        _error = 'Error verifying admin status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() => _isLoading = true);

      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      // Fetch users and their data
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Fetch expenses for the selected month
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      // Fetch budgets for the selected month
      final budgetsSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .get();

      // Calculate basic metrics
      final totalUsers = usersSnapshot.docs.length;
      final activeUsers = expensesSnapshot.docs
          .map((e) => e.data()['userId'] as String)
          .toSet()
          .length;

      final totalExpenses = expensesSnapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc.data()['amount'] as num));

      // Calculate category totals and analysis
      final categoryTotals = <String, double>{};
      final categoryTransactions = <String, int>{};
      for (final doc in expensesSnapshot.docs) {
        final category = doc.data()['category'] as String;
        final amount = doc.data()['amount'] as num;
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
        categoryTransactions[category] = (categoryTransactions[category] ?? 0) + 1;
      }

      // Calculate weekly trends
      final weeklyTrends = <String, double>{};
      for (final doc in expensesSnapshot.docs) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        final weekKey = DateFormat('yyyy-ww').format(date);
        final amount = doc.data()['amount'] as num;
        weeklyTrends[weekKey] = (weeklyTrends[weekKey] ?? 0.0) + amount.toDouble();
      }

      // Calculate budget utilization
      int overBudgetUsers = 0;
      int underBudgetUsers = 0;
      double totalBudgetUtilization = 0;

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userExpenses = expensesSnapshot.docs
            .where((doc) => doc.data()['userId'] == userId)
            .fold(0.0, (sum, doc) => sum + (doc.data()['amount'] as num));
        
        final userBudget = budgetsSnapshot.docs
            .where((doc) => doc.id == userId)
            .fold(0.0, (sum, doc) => sum + (doc.data()['monthlyBudget'] as num? ?? 0));

        if (userBudget > 0) {
          final utilization = userExpenses / userBudget;
          totalBudgetUtilization += utilization;
          if (utilization > 1) overBudgetUsers++;
          if (utilization < 0.8) underBudgetUsers++;
        }
      }

      // Calculate category-wise analysis
      _categoryWiseAnalysis = categoryTotals.entries.map((entry) {
        final category = entry.key;
        final total = entry.value;
        final transactions = categoryTransactions[category] ?? 0;
        final averagePerTransaction = total / transactions;
        
        return {
          'category': category,
          'total': total,
          'transactions': transactions,
          'averagePerTransaction': averagePerTransaction,
          'percentageOfTotal': total / totalExpenses * 100,
        };
      }).toList();
      
      // Sort by total amount
      _categoryWiseAnalysis.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

      // Calculate top spenders
      await _calculateTopSpenders(startOfMonth, endOfMonth);

      // Convert entries to list and sort
      List<MapEntry<String, int>> sortedEntries = categoryTransactions.entries.toList();
      sortedEntries.sort((a, b) => b.value.compareTo(a.value));
      
      // Take top 5 and extract categories
      List<String> topCategories = [];
      for (var i = 0; i < 5 && i < sortedEntries.length; i++) {
        topCategories.add(sortedEntries[i].key);
      }

      setState(() {
        _analytics = {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'totalExpenses': totalExpenses,
          'averageExpense': activeUsers > 0 ? totalExpenses / activeUsers : 0,
          'categoryTotals': categoryTotals,
          'weeklyTrends': weeklyTrends,
          'budgetUtilization': totalBudgetUtilization / totalUsers,
          'overBudgetUsers': overBudgetUsers,
          'underBudgetUsers': underBudgetUsers,
          'mostUsedCategories': topCategories,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error fetching analytics: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateTopSpenders(DateTime start, DateTime end) async {
    final expensesByUser = <String, Map<String, dynamic>>{};
    final userNames = <String, String>{};

    // Get all expenses for the month
    final expenses = await FirebaseFirestore.instance
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    // Calculate total expenses and categories per user
    for (final doc in expenses.docs) {
      final userId = doc.data()['userId'] as String;
      final amount = doc.data()['amount'] as num;
      final category = doc.data()['category'] as String;

      if (!expensesByUser.containsKey(userId)) {
        expensesByUser[userId] = {
          'total': 0.0,
          'categories': <String>{},
          'transactions': 0,
        };
      }

      final userData = expensesByUser[userId]!;
      userData['total'] = (userData['total'] as double) + amount;
      (userData['categories'] as Set<String>).add(category);
      userData['transactions'] = (userData['transactions'] as int) + 1;
    }

    // Get user names and additional info
    for (final userId in expensesByUser.keys) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        userNames[userId] = data['name'] ?? 'Unknown User';
        
        // Get user's budget
        final budgetDoc = await FirebaseFirestore.instance
            .collection('budgets')
            .doc(userId)
            .collection('monthlyBudgets')
            .doc(DateFormat('yyyy-MM').format(start))
            .get();

        if (budgetDoc.exists) {
          final monthlyBudget = budgetDoc.data()?['monthlyBudget'] as num? ?? 0;
          expensesByUser[userId]!['budget'] = monthlyBudget;
          expensesByUser[userId]!['budgetUtilization'] = 
              monthlyBudget > 0 ? (expensesByUser[userId]!['total'] as double) / monthlyBudget : 0;
        }
      }
    }

    // Sort users by expense amount
    final sortedSpenders = expensesByUser.entries.toList()
      ..sort((a, b) => (b.value['total'] as double).compareTo(a.value['total'] as double));

    setState(() {
      _topSpenders = sortedSpenders.take(5).map((entry) => {
        'userId': entry.key,
        'name': userNames[entry.key] ?? 'Unknown User',
        'total': entry.value['total'] as double,
        'categories': (entry.value['categories'] as Set<String>).length,
        'transactions': entry.value['transactions'] as int,
        'budget': entry.value['budget'] ?? 0.0,
        'budgetUtilization': entry.value['budgetUtilization'] ?? 0.0,
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Analytics'),
          backgroundColor: Colors.teal[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin-home'),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        backgroundColor: Colors.teal[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin-home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() => _selectedMonth = picked);
                await _fetchAnalytics();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildBudgetInsights(),
                    const SizedBox(height: 24),
                    _buildCategoryAnalysis(),
                    const SizedBox(height: 24),
                    _buildTopSpendersList(),
                    const SizedBox(height: 24),
                    _buildWeeklyTrendChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final formatter = NumberFormat('#,##,###.##');
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Users',
          _analytics['totalUsers'].toString(),
          Icons.people,
          'Total registered users',
        ),
        _buildMetricCard(
          'Active Users',
          '${_analytics['activeUsers']} (${(_analytics['activeUsers'] / _analytics['totalUsers'] * 100).toStringAsFixed(1)}%)',
          Icons.person_outline,
          'Users with expenses this month',
        ),
        _buildMetricCard(
          'Total Expenses',
          '₹${formatter.format(_analytics['totalExpenses'])}',
          Icons.money,
          'Total spending this month',
        ),
        _buildMetricCard(
          'Avg. per User',
          '₹${formatter.format(_analytics['averageExpense'])}',
          Icons.person,
          'Average spending per active user',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, String tooltip) {
    return Card(
      elevation: 4,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.teal),
              const SizedBox(height: 8),
              Text(title, 
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(value, 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInsightItem(
                  'Over Budget',
                  _analytics['overBudgetUsers'].toString(),
                  Icons.warning,
                  Colors.red,
                ),
                _buildInsightItem(
                  'Under Budget',
                  _analytics['underBudgetUsers'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildInsightItem(
                  'Avg. Utilization',
                  '${(_analytics['budgetUtilization'] * 100).toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCategoryAnalysis() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._categoryWiseAnalysis.take(5).map((category) {
              final percentage = category['percentageOfTotal'].toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category['category'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('₹${NumberFormat('#,##,###.##').format(category['total'])}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: category['percentageOfTotal'] / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.teal.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${category['transactions']} transactions',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$percentage% of total',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpendersList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Spenders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._topSpenders.map((spender) {
              final budgetUtilization = spender['budgetUtilization'] as double;
              final utilizationColor = budgetUtilization > 1 
                  ? Colors.red 
                  : budgetUtilization > 0.8 
                      ? Colors.orange 
                      : Colors.green;
              
              return ListTile(
                title: Text(spender['name']),
                subtitle: Text(
                  '${spender['transactions']} transactions in ${spender['categories']} categories',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(spender['total'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(budgetUtilization * 100).toStringAsFixed(1)}% of budget',
                      style: TextStyle(
                        color: utilizationColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    final weeklyData = _analytics['weeklyTrends'] as Map<String, double>;
    if (weeklyData.isEmpty) return const SizedBox.shrink();

    final sortedWeeks = weeklyData.keys.toList()..sort();
    final spots = sortedWeeks.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), weeklyData[entry.value]!);
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Spending Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('₹${NumberFormat.compact().format(value)}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedWeeks.length) {
                            return Text('W${value.toInt() + 1}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.2),
                      ),
                    ),
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

