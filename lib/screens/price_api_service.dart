import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceApiService {
  final String _apiKey =
      "PWCLHWGGWAZVQYOMVUJAIWAGKUCWSILXFAFYMSAHXHZNPRKKFUYZULBLLTWKBWEK";
  final String _apiBaseUrl = "https://api.priceapi.com/v2";

  /// ✅ Submit a job to compare product prices
  Future<String> submitJob(String searchTerm) async {
    final formattedSearchTerm = searchTerm
        .split(',')
        .map((term) => term.trim())
        .join('\n'); // newline-separated values

    final Uri url =
        Uri.parse("https://api.priceapi.com/v2/jobs?token=$_apiKey");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "source": "google_shopping",
        "country": "us",
        "topic": "search_results",
        "key": "term",
        "values": formattedSearchTerm,
        "max_pages": 1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final jobId = data['job_id'];
      if (jobId != null) {
        return jobId;
      } else {
        throw Exception("❌ API Error: job_id missing in response.");
      }
    } else {
      print("❌ Job Submission Failed: ${response.body}");
      throw Exception("❌ Server Error: ${response.statusCode}");
    }
  }

  /// ✅ Check job status until it's finished
  Future<String> checkJobStatus(String jobId) async {
    final Uri url = Uri.parse("$_apiBaseUrl/jobs/$jobId?token=$_apiKey");

    while (true) {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 Job Status Response: $data");

        if (data['status'] == "finished") {
          return "$_apiBaseUrl/jobs/$jobId/download";
        } else if (data['status'] == "error") {
          throw Exception("❌ Job Error: ${data['comment'] ?? 'Unknown error'}");
        } else {
          await Future.delayed(const Duration(seconds: 5));
        }
      } else {
        print("❌ Job Status Error: ${response.body}");
        throw Exception("❌ Failed to check job status");
      }
    }
  }

  /// ✅ Download and parse job results
  Future<List<dynamic>> getResults(String downloadUrl) async {
    final Uri url = Uri.parse("$downloadUrl?token=$_apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("🔍 Full Download Response: $data");

      if (data.containsKey('results') && data['results'] is List) {
        final results = data['results'];
        for (var result in results) {
          if (result.containsKey('content') && 
              result['content'].containsKey('search_results')) {
            return result['content']['search_results'];
          }
        }
        return [];
      } else {
        throw Exception("❌ Invalid response format: No results found");
      }
    } else {
      print("❌ Download Error: ${response.body}");
      throw Exception("❌ Failed to download results");
    }
  }

  /// ✅ Complete process: Submit job → Check status → Get results
  Future<List<dynamic>> fetchProductPrices(String searchTerm) async {
    try {
      String jobId = await submitJob(searchTerm);
      print("✅ Job submitted: $jobId");

      String downloadUrl = await checkJobStatus(jobId);
      print("✅ Job finished. Downloading results...");

      return await getResults(downloadUrl);
    } catch (e) {
      throw Exception("❌ Error fetching product prices. $e");
    }
  }
}
