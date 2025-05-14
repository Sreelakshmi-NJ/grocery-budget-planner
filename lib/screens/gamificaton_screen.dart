import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  int _totalPoints = 0;
  List<MonthlyAchievement> _monthlyStats = [];
  String _currentTitle = 'Budget Novice';
  List<bool> _puzzlePieces = List.generate(12, (_) => false);
  int _pointsToNextTitle = 0;
  String _nextTitle = '';
  bool _canEarnPointsThisMonth = false;
  DateTime? _currentMonthEnd;

  final _yearlyTitles = {
    'Budget Novice': 0,
    'Budget Saver': 30,
    'Budget Pro': 60,
    'Budget Expert': 90,
    'Budget Master': 120,
  };

  final _tips = {
    'Budget Novice': 'Start your savings journey! Try to stay within budget this month.',
    'Budget Saver': 'Great start! Try categorizing expenses to find more savings opportunities.',
    'Budget Pro': 'You\'re doing well! Consider meal planning to save more on groceries.',
    'Budget Expert': 'Almost there! Share your success with friends and challenge them.',
    'Budget Master': 'Congratulations! You\'ve mastered budget management!',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _calculateCurrentMonthStatus();
    _initializeHistoricalData();
  }

  Future<void> _initializeHistoricalData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Historical data for Q1 2025
    final historicalData = [
      MonthlyAchievement(
        monthKey: '2025-01',
        budget: 5000.0,
        spent: 4200.0,
        saved: true,
        points: 10,
        timestamp: DateTime(2025, 1, 31),
      ),
      MonthlyAchievement(
        monthKey: '2025-02',
        budget: 5000.0,
        spent: 4800.0,
        saved: true,
        points: 10,
        timestamp: DateTime(2025, 2, 28),
      ),
      MonthlyAchievement(
        monthKey: '2025-03',
        budget: 5000.0,
        spent: 4600.0,
        saved: true,
        points: 10,
        timestamp: DateTime(2025, 3, 31),
      ),
    ];

    // Check if historical data already exists
    final statsRef = _fs
        .collection('gamification')
        .doc(uid)
        .collection('monthlyStats');

    final batch = _fs.batch();
    var totalPoints = 0;
    var newPuzzlePieces = List.generate(12, (_) => false);

    for (var achievement in historicalData) {
      final doc = await statsRef.doc(achievement.monthKey).get();
      if (!doc.exists) {
        batch.set(statsRef.doc(achievement.monthKey), achievement.toMap());
        totalPoints += achievement.points;

        // Update puzzle pieces
        final monthIndex = int.parse(achievement.monthKey.split('-')[1]) - 1;
        if (monthIndex >= 0 && monthIndex < 12) {
          newPuzzlePieces[monthIndex] = true;
        }
      }
    }

    // Update main gamification document with total points and puzzle pieces
    batch.set(
      _fs.collection('gamification').doc(uid),
      {
        'totalPoints': totalPoints,
        'currentTitle': 'Budget Pro',
        'puzzlePieces': newPuzzlePieces,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await _loadData(); // Reload data to reflect changes
  }

  Future<void> _calculateCurrentMonthStatus() async {
    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(now);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Get current month's budget
    final budgetDoc = await _fs
        .collection('budgets')
        .doc(uid)
        .collection('monthlyBudgets')
        .doc(monthKey)
        .get();

    if (!budgetDoc.exists) {
      setState(() {
        _canEarnPointsThisMonth = false;
      });
      return;
    }

    // Check if points were already awarded
    final achievementDoc = await _fs
        .collection('gamification')
        .doc(uid)
        .collection('monthlyStats')
        .doc(monthKey)
        .get();

    // Calculate month end
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    setState(() {
      _currentMonthEnd = lastDayOfMonth;
      _canEarnPointsThisMonth = !achievementDoc.exists;
    });
  }

  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Load user's gamification data
    final gamDoc = await _fs.collection('gamification').doc(uid).get();
    
    if (gamDoc.exists) {
      final data = gamDoc.data()!;
      setState(() {
        _totalPoints = data['totalPoints'] ?? 0;
        // Ensure we always have 12 elements
        final puzzlePieces = data['puzzlePieces'] as List<dynamic>?;
        _puzzlePieces = puzzlePieces != null 
            ? List.generate(12, (i) => i < puzzlePieces.length ? puzzlePieces[i] as bool : false)
            : List.generate(12, (_) => false);
      });
    }

    // Load monthly achievements
    final statsSnap = await _fs
        .collection('gamification')
        .doc(uid)
        .collection('monthlyStats')
        .orderBy('monthKey', descending: true)
        .get();

    final achievements = statsSnap.docs
        .map((doc) => MonthlyAchievement.fromMap(doc.data()))
        .toList();

    setState(() {
      _monthlyStats = achievements;
      _updateTitleProgress();
    });
  }

  void _updateTitleProgress() {
    var sortedTitles = _yearlyTitles.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (var i = 0; i < sortedTitles.length; i++) {
      if (_totalPoints < sortedTitles[i].value) {
        _currentTitle = i == 0 ? sortedTitles[0].key : sortedTitles[i - 1].key;
        _nextTitle = sortedTitles[i].key;
        _pointsToNextTitle = sortedTitles[i].value - _totalPoints;
        break;
      }
    }
    
    if (_totalPoints >= sortedTitles.last.value) {
      _currentTitle = sortedTitles.last.key;
      _nextTitle = '';
      _pointsToNextTitle = 0;
    }
  }

  Future<void> _checkAndAward() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(now);
    
    // Verify if it's end of month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    if (now.day != lastDayOfMonth.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Points will be awarded on ${DateFormat('MMMM dd').format(lastDayOfMonth)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if points were already awarded
    final existingAchievement = await _fs
        .collection('gamification')
        .doc(uid)
        .collection('monthlyStats')
        .doc(monthKey)
        .get();

    if (existingAchievement.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points have already been awarded for this month'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get monthly budget
    final budgetDoc = await _fs
        .collection('budgets')
        .doc(uid)
        .collection('monthlyBudgets')
        .doc(monthKey)
        .get();

    if (!budgetDoc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No budget set for this month'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final budget = (budgetDoc.data()!['monthlyBudget'] ?? 0).toDouble();

    // Calculate total spending
    final expensesSnap = await _fs
        .collection('expenses')
        .where('userId', isEqualTo: uid)
        .where('monthKey', isEqualTo: monthKey)
        .get();

    final spent = expensesSnap.docs.fold<double>(
      0,
      (total, doc) => total + (doc.data()['amount'] ?? 0).toDouble(),
    );

    final saved = spent <= budget;
    final achievement = MonthlyAchievement(
      monthKey: monthKey,
      budget: budget,
      spent: spent,
      saved: saved,
      points: saved ? 10 : 0,
      timestamp: now,
    );

    // Update Firestore
    final batch = _fs.batch();
    
    // Add monthly achievement
    batch.set(
      _fs
          .collection('gamification')
          .doc(uid)
          .collection('monthlyStats')
          .doc(monthKey),
      achievement.toMap(),
    );

    // Update total points and puzzle pieces
    final monthIndex = now.month - 1;
    final newPuzzlePieces = List<bool>.from(_puzzlePieces);
    if (saved && monthIndex >= 0 && monthIndex < 12) {
      newPuzzlePieces[monthIndex] = true;
    }

    batch.set(
      _fs.collection('gamification').doc(uid),
      {
        'totalPoints': _totalPoints + (saved ? 10 : 0),
        'currentTitle': saved && (_totalPoints + 10) >= 120 ? 'Budget Master' : _currentTitle,
        'puzzlePieces': newPuzzlePieces,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Update local state
    setState(() {
      if (saved) {
        _totalPoints += 10;
        if (monthIndex >= 0 && monthIndex < 12) {
          _puzzlePieces[monthIndex] = true;
        }
      }
      _monthlyStats.insert(0, achievement);
      _updateTitleProgress();
      _canEarnPointsThisMonth = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Congratulations! You stayed under budget and earned 10 points! Saved: ₨${(budget - spent).toStringAsFixed(0)}'
              : 'Over budget by ₨${(spent - budget).toStringAsFixed(0)}. Try again next month!',
        ),
        backgroundColor: saved ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        backgroundColor: Colors.teal[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
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
              // Points and Progress Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Points',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _totalPoints.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currentTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_nextTitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_pointsToNextTitle points to $_nextTitle',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (_nextTitle.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _totalPoints / _yearlyTitles[_nextTitle]!,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _tips[_currentTitle] ?? _tips['Budget Novice']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current Month Status
              if (_canEarnPointsThisMonth) ...[
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'April Challenge in Progress',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stay within your budget until ${DateFormat('MMMM dd').format(_currentMonthEnd!)} '
                          'to earn 10 points!',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Spend wisely! Your April points will be awarded at the end of the month.',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_totalPoints < 120) ...[
                          const SizedBox(height: 12),
                          Text(
                            'You\'re doing great! Keep saving to become a Budget Master!',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Monthly Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_canEarnPointsThisMonth)
                    TextButton.icon(
                      onPressed: _checkAndAward,
                      icon: const Icon(Icons.stars),
                      label: const Text('Check Points'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_monthlyStats.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Start saving to earn points! You\'ll get 10 points for each month you stay within budget.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _monthlyStats.length,
                  itemBuilder: (context, index) {
                    final stat = _monthlyStats[index];
                    final month = DateFormat('MMMM yyyy')
                        .format(DateFormat('yyyy-MM').parse(stat.monthKey));
                    final isCurrentMonth = stat.monthKey == currentMonthKey;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          stat.saved ? Icons.check_circle : Icons.cancel,
                          color: stat.saved ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        title: Text(month),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget: ₨${stat.budget.toStringAsFixed(0)}\n'
                              'Spent: ₨${stat.spent.toStringAsFixed(0)}',
                            ),
                            if (stat.saved)
                              Text(
                                'Saved: ₨${(stat.budget - stat.spent).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: stat.saved
                            ? const Chip(
                                label: Text('+10'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Puzzle Progress
              Text(
                'Budget Master Puzzle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collect all 12 pieces by staying within budget each month!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = DateFormat('MMM').format(DateTime(now.year, index + 1));
                          final isCurrentMonth = index == now.month - 1;
                          final isLocked = index > 2; // First 3 months unlocked

                          // Special achievements and data for unlocked months
                          final specialAchievements = {
                            0: 'Smart Shopper Elite',    // January
                            1: 'Budget Master Pro',      // February
                            2: 'Savings Champion',     // March
                          };

                          final savingsData = {
                            0: {'budget': 5000.0, 'spent': 4200.0, 'items': 45, 'savings': 800.0},
                            1: {'budget': 5000.0, 'spent': 4800.0, 'items': 52, 'savings': 200.0},
                            2: {'budget': 5000.0, 'spent': 4600.0, 'items': 48, 'savings': 400.0},
                          };

                          final savingsTips = {
                            0: 'Mastered bulk buying & seasonal deals',
                            1: 'Expert at price comparison shopping',
                            2: 'Pro meal planning & inventory management',
                          };

                          final achievements = {
                            0: [
                              'Saved ₨800 (16% savings)',
                              'Used 15 coupons',
                              'Found 5 bulk deals',
                              'Bought seasonal items',
                              'Earned 50 bonus points'
                            ],
                            1: [
                              'Saved ₨200 (4% savings)',
                              'Price compared 30 items',
                              'Found 8 store discounts',
                              'Used shopping list',
                              'Earned 30 bonus points'
                            ],
                            2: [
                              'Saved ₨400 (8% savings)',
                              'Planned 4 weeks meals',
                              'Zero food waste',
                              'Used pantry inventory',
                              'Earned 40 bonus points'
                            ],
                          };

                          final badges = {
                            0: {'icon': Icons.star, 'color': Colors.amber},
                            1: {'icon': Icons.workspace_premium, 'color': Colors.purple},
                            2: {'icon': Icons.emoji_events, 'color': Colors.orange},
                          };

                          return Card(
                            elevation: !isLocked ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: !isLocked
                                    ? LinearGradient(
                                        colors: [
                                          Colors.teal.shade700,
                                          Colors.teal.shade900,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isLocked ? Colors.grey[300] : null,
                              ),
                              child: Stack(
                                children: [
                                  if (!isLocked && badges.containsKey(index))
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: badges[index]!['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          badges[index]!['icon'] as IconData,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: !isLocked
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                month,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              if (specialAchievements.containsKey(index)) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    specialAchievements[index]!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (savingsData.containsKey(index)) ...[
                                                  Text(
                                                    'Budget: ₨${(savingsData[index]!['budget'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Spent: ₨${(savingsData[index]!['spent'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Items: ${savingsData[index]!['items']}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Saved ₨${(savingsData[index]!['savings'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                if (savingsTips.containsKey(index))
                                                  Text(
                                                    savingsTips[index]!,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 10,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                const SizedBox(height: 8),
                                                ...achievements[index]!.map((achievement) =>
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.check_circle_outline,
                                                          color: Colors.white70,
                                                          size: 12,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            achievement,
                                                            style: const TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  month,
                                                  style: TextStyle(
                                                    color: isCurrentMonth
                                                        ? Colors.teal
                                                        : Colors.black54,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                if (isLocked)
                                                  const Icon(
                                                    Icons.lock,
                                                    color: Colors.black45,
                                                    size: 24,
                                                  ),
                                              ],
                                            ),
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
}

class MonthlyAchievement {
  final String monthKey;
  final double budget;
  final double spent;
  final bool saved;
  final int points;
  final DateTime timestamp;

  MonthlyAchievement({
    required this.monthKey,
    required this.budget,
    required this.spent,
    required this.saved,
    required this.points,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'monthKey': monthKey,
        'budget': budget,
        'spent': spent,
        'saved': saved,
        'points': points,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory MonthlyAchievement.fromMap(Map<String, dynamic> m) {
    return MonthlyAchievement(
      monthKey: m['monthKey'],
      budget: (m['budget'] ?? 0).toDouble(),
      spent: (m['spent'] ?? 0).toDouble(),
      saved: m['saved'] ?? false,
      points: m['points'] ?? 0,
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}