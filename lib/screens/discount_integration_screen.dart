import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DiscountIntegrationScreen extends StatefulWidget {
  const DiscountIntegrationScreen({super.key});

  @override
  _DiscountIntegrationScreenState createState() =>
      _DiscountIntegrationScreenState();
}

class _DiscountIntegrationScreenState extends State<DiscountIntegrationScreen> {
  List<Map<String, dynamic>> _discounts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  /// Fetches discount data from the Open Food Facts API.
  Future<void> _fetchDiscounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?search_terms=discount&search_simple=1&action=process&json=1&lc=en'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] != null && data['products'] is List) {
          final products = data['products'] as List<dynamic>;
          setState(() {
            _discounts = products.map((product) {
              return {
                'store': product['stores_tags']?.join(', ') ?? 'Unknown Store',
                'offer':
                    product['product_name'] ?? 'No offer details available',
              };
            }).toList();
          });
        } else {
          setState(() {
            _error = 'No products found in the response.';
          });
        }
      } else {
        throw Exception('Failed to load discounts');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
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
        title: const Text('Discounts & Offers'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                Navigator.pushNamed(context, '/help');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background image with a grocery theme.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.pexels.com/photos/6164040/pexels-photo-6164040.jpeg?auto=compress&cs=tinysrgb&w=1600',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay for readability.
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text('Error: $_error',
                          style: const TextStyle(color: Colors.white)))
                  : _discounts.isEmpty
                      ? const Center(
                          child: Text('No discounts available.',
                              style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: _discounts.length,
                          itemBuilder: (context, index) {
                            final discount = _discounts[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.local_offer,
                                    color: Colors.red),
                                title: Text(discount['store'],
                                    style: const TextStyle(fontSize: 18)),
                                subtitle: Text(discount['offer'],
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          },
                        ),
        ],
      ),
    );
  }
}
