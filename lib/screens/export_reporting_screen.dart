import 'dart:convert';
import 'dart:io';
import 'dart:html' if (dart.library.html) 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportReportingScreen extends StatefulWidget {
  const ExportReportingScreen({super.key});

  @override
  State<ExportReportingScreen> createState() => _ExportReportingScreenState();
}

class _ExportReportingScreenState extends State<ExportReportingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String _error = '';
  String _infoMessage = '';

  Future<void> _downloadFileWeb(String content, String filename) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _generateAndDownloadReport() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _infoMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);

      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('monthKey', isEqualTo: monthKey)
          .get();

      if (expensesSnapshot.docs.isEmpty) {
        setState(() {
          _infoMessage =
              'No expenses found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
        });
        return;
      }

      final sortedDocs = expensesSnapshot.docs..sort((a, b) {
          final aDate = (a.data()['createdAt'] as Timestamp).toDate();
          final bDate = (b.data()['createdAt'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

      StringBuffer csvContent = StringBuffer();
      csvContent.write('\uFEFF'); // UTF-8 BOM
      csvContent.writeln('Date,Category,Description,Amount (₹)');

      double totalExpenses = 0;

      for (var doc in sortedDocs) {
        final data = doc.data();
        final date = (data['createdAt'] as Timestamp).toDate();
        final amount = (data['amount'] as num).toDouble();
        final category = data['category'] ?? 'Uncategorized';
        final description = data['description'] ?? 'No description';

        final escapedCategory = '"${category.replaceAll('"', '""')}"';
        final escapedDescription = '"${description.replaceAll('"', '""')}"';

        csvContent.writeln(
            '${DateFormat('dd/MM/yyyy, hh:mm a').format(date)},$escapedCategory,$escapedDescription,${amount.toStringAsFixed(2)}');

        totalExpenses += amount;
      }

      csvContent.writeln('');
      csvContent.writeln('Report Summary');
      csvContent.writeln('Period,${DateFormat('MMMM yyyy').format(_selectedMonth)}');
      csvContent.writeln('Total Expenses,${totalExpenses.toStringAsFixed(2)}');

      final fileName = 'Expenses_${DateFormat('MMMM_yyyy').format(_selectedMonth)}.csv';

      if (kIsWeb) {
        await _downloadFileWeb(csvContent.toString(), fileName);
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent.toString());
        await Share.shareFiles([file.path], text: 'Expense Report for ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
      }

      setState(() {
        _infoMessage =
            'Report generated successfully for ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate report: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
        backgroundColor: Colors.teal[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[700]!,
              Colors.teal[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Month for Report',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedMonth,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDatePickerMode: DatePickerMode.year,
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedMonth = DateTime(picked.year, picked.month);
                              _error = '';
                              _infoMessage = '';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, color: Colors.teal[700]),
                              const SizedBox(width: 12),
                              Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateAndDownloadReport,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isLoading ? 'Generating...' : 'Download Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_infoMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_infoMessage, style: TextStyle(color: Colors.blue[700])),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
