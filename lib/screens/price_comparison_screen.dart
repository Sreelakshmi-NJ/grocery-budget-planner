import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'price_api_service.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  PriceComparisonScreenState createState() => PriceComparisonScreenState();
}

class PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PriceApiService _priceService = PriceApiService();
  List<dynamic> _priceData = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final FocusNode _searchFocusNode = FocusNode();

  // Map of product categories to their respective icons
  final Map<String, IconData> _categoryIcons = {
    'milk': Icons.water_drop,
    'rice': Icons.grain,
    'bread': Icons.breakfast_dining,
    'meat': Icons.restaurant,
    'vegetables': Icons.eco,
    'fruits': Icons.apple,
    'snacks': Icons.cookie,
    'beverages': Icons.local_drink,
    'default': Icons.shopping_basket,
  };

  IconData _getCategoryIcon(String productName) {
    productName = productName.toLowerCase();
    for (var entry in _categoryIcons.entries) {
      if (productName.contains(entry.key)) {
        return entry.value;
      }
    }
    return _categoryIcons['default']!;
  }

  Color _getCategoryColor(String productName) {
    productName = productName.toLowerCase();
    if (productName.contains('milk')) return Colors.blue[200]!;
    if (productName.contains('rice')) return Colors.amber[200]!;
    if (productName.contains('bread')) return Colors.brown[200]!;
    if (productName.contains('meat')) return Colors.red[200]!;
    if (productName.contains('vegetables')) return Colors.green[200]!;
    if (productName.contains('fruits')) return Colors.orange[200]!;
    if (productName.contains('snacks')) return Colors.purple[200]!;
    if (productName.contains('beverages')) return Colors.teal[200]!;
    return Colors.grey[200]!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Rebuild to update clear button visibility
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Fetch product prices from API
  Future<void> _fetchPrices() async {
    // Unfocus before making the API call to prevent pointer event issues
    _searchFocusNode.unfocus();
    
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a product name.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _priceData.clear();
    });

    try {
      final data = await _priceService.fetchProductPrices(searchTerm);
      if (!mounted) return;

      setState(() {
        _priceData = data;
        _isLoading = false;
        _errorMessage = data.isEmpty ? "No prices found for this product." : "";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to fetch prices. Please try again.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Open product link in browser
  Future<void> _launchURL(String url) async {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch URL');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open the link"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildProductImage(String productName) {
    final color = _getCategoryColor(productName);
    final icon = _getCategoryIcon(productName);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: color.withOpacity(0.8),
          ),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                productName.split(' ')[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_priceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Search for products to compare prices",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _priceData.length,
      itemBuilder: (context, index) {
        final item = _priceData[index];
        final String name = item['name'] ?? 'No Name';
        final String price = item['min_price']?.toString() ?? 'N/A';
        final String merchant = item['merchant'] ?? '';
        final String productUrl = item['url'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _launchURL(productUrl),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(name),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹$price",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (merchant.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Seller: $merchant",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Price Comparison'),
          backgroundColor: Colors.teal[700],
          elevation: 0,
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Search Products",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Compare prices across different stores",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: "e.g. Rice, Milk, Shampoo...",
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _priceData.clear();
                                    _errorMessage = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _fetchPrices(),
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fetchPrices,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Compare Prices",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPriceList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
