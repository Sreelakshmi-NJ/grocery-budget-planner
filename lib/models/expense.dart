import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String monthKey;
  final bool isItemized;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.monthKey,
    this.isItemized = true,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      monthKey: data['monthKey'] ?? '',
      isItemized: data['isItemized'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'monthKey': monthKey,
      'isItemized': isItemized,
    };
  }
} 