import 'package:flutter/material.dart';
import 'ai_suggestions_service.dart'; // Import your service file

class AISuggestionsScreen extends StatefulWidget {
  const AISuggestionsScreen({super.key});

  @override
  _AISuggestionsScreenState createState() => _AISuggestionsScreenState();
}

class _AISuggestionsScreenState extends State<AISuggestionsScreen> {
  final _budgetController = TextEditingController();
  final _spentController = TextEditingController();
  String _status = '';
  List<String> _tips = [];
  bool _isLoading = false;

  Future<void> _fetchSuggestions() async {
    if (_budgetController.text.isEmpty || _spentController.text.isEmpty) {
      setState(() {
        _status = 'Please enter both budget and spent amounts';
      });
      return;
    }

    final double budget = double.tryParse(_budgetController.text) ?? 0;
    final double spent = double.tryParse(_spentController.text) ?? 0;

    if (budget <= 0) {
      setState(() {
        _status = 'Please enter a valid budget amount';
      });
      return;
    }

    if (spent < 0) {
      setState(() {
        _status = 'Spent amount cannot be negative';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '';
      _tips = [];
    });

    try {
      if (AISuggestionsService.apiKey == 'YOUR_OPENAI_API_KEY') {
        throw Exception('Please configure your OpenAI API key in ai_suggestions_service.dart');
      }

      final service = AISuggestionsService();
      final tips = await service.fetchSuggestions(budget, spent);
      
      setState(() {
        _status = 'AI-powered suggestions generated successfully!';
        _tips = tips;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _spentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Cost-Saving Suggestions"),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Get AI-Powered Cost-Saving Tips",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Monthly Budget (₹)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _spentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Current Spent (₹)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.money_off),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.teal,
                            ),
                            onPressed: _fetchSuggestions,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text(
                              "Get AI Suggestions",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    const SizedBox(height: 24),
                    if (_status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _status.startsWith('Error')
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _status.startsWith('Error')
                                ? Colors.red[900]
                                : Colors.green[900],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_tips.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        "Personalized Suggestions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_tips.length, (index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(_tips[index]),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
