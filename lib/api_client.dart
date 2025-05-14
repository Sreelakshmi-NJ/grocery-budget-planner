import 'dart:convert';
import 'package:http/http.dart' as http;

class AISuggestionsService {
  final String baseUrl;

  AISuggestionsService({required this.baseUrl});

  Future<List<String>> getCostSavingSuggestions(
      double monthlyBudget, double currentSpent) async {
    // Ensure the URL matches the endpoint defined in your Flask backend.
    final url = Uri.parse('$baseUrl/suggestions');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'monthlyBudget': monthlyBudget,
        'currentSpent': currentSpent,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Expecting data to have a "tips" array.
      List<dynamic> tips = data['tips'];
      return tips.map((tip) => tip.toString()).toList();
    } else {
      throw Exception('Failed to fetch suggestions: ${response.statusCode}');
    }
  }
}
