import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

enum ItemType {
  perishable,  // Items like fruits, vegetables, bread
  nonPerishable,  // Items like canned goods, rice
  frozen  // Frozen items
}

enum ItemCategory {
  grainsPasta,
  cannedGoods,
  bakingSupplies,
  spicesSeasonings,
  oilsVinegars,
  condimentsSauces,
  snacksCereals,
  legumesNuts,
  breakfastItems,
  sweeteners,
  beverages
}

class PantryItem {
  final String name;
  final double quantity;
  final ItemType type;
  final ItemCategory category;
  final DateTime? expiryDate;
  final String unit;
  final bool trackLowStock;
  final double lowStockThreshold;

  PantryItem({
    required this.name,
    required this.quantity,
    required this.type,
    required this.category,
    this.expiryDate,
    required this.unit,
    this.trackLowStock = false,
    this.lowStockThreshold = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'type': type.toString(),
      'category': category.toString(),
      'expiryDate': expiryDate?.toIso8601String(),
      'unit': unit,
      'trackLowStock': trackLowStock,
      'lowStockThreshold': lowStockThreshold,
      'monthKey': DateFormat('yyyy-MM').format(DateTime.now()),
    };
  }
}

class PantryManagementScreen extends StatefulWidget {
  const PantryManagementScreen({super.key});

  @override
  State<PantryManagementScreen> createState() => _PantryManagementScreenState();
}

class _PantryManagementScreenState extends State<PantryManagementScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _lowStockThresholdController = TextEditingController();
  ItemType _selectedType = ItemType.perishable;
  ItemCategory _selectedCategory = ItemCategory.grainsPasta;
  DateTime? _selectedExpiryDate;
  String _selectedUnit = 'units';
  bool _trackLowStock = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  Map<ItemCategory, List<String>> categoryUnits = {
    ItemCategory.grainsPasta: ['kg', 'g', 'packets', 'boxes'],
    ItemCategory.cannedGoods: ['cans', 'pieces', 'g'],
    ItemCategory.bakingSupplies: ['kg', 'g', 'cups', 'packets'],
    ItemCategory.spicesSeasonings: ['g', 'bottles', 'packets', 'jars'],
    ItemCategory.oilsVinegars: ['l', 'ml', 'bottles'],
    ItemCategory.condimentsSauces: ['bottles', 'jars', 'packets', 'g'],
    ItemCategory.snacksCereals: ['boxes', 'packets', 'g', 'kg'],
    ItemCategory.legumesNuts: ['kg', 'g', 'packets', 'cups'],
    ItemCategory.breakfastItems: ['boxes', 'packets', 'g', 'kg'],
    ItemCategory.sweeteners: ['kg', 'g', 'bottles', 'packets'],
    ItemCategory.beverages: ['l', 'ml', 'bottles', 'packets'],
  };

  String getCategoryDisplayName(ItemCategory category) {
    switch (category) {
      case ItemCategory.grainsPasta:
        return 'Grains & Pasta';
      case ItemCategory.cannedGoods:
        return 'Canned Goods';
      case ItemCategory.bakingSupplies:
        return 'Baking Supplies';
      case ItemCategory.spicesSeasonings:
        return 'Spices & Seasonings';
      case ItemCategory.oilsVinegars:
        return 'Oils & Vinegars';
      case ItemCategory.condimentsSauces:
        return 'Condiments & Sauces';
      case ItemCategory.snacksCereals:
        return 'Snacks & Cereals';
      case ItemCategory.legumesNuts:
        return 'Legumes & Nuts';
      case ItemCategory.breakfastItems:
        return 'Breakfast Items';
      case ItemCategory.sweeteners:
        return 'Sweeteners';
      case ItemCategory.beverages:
        return 'Beverages';
    }
  }

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _checkExpiringItems();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestNotificationPermission() async {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      if (permission != 'granted') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable notifications to receive expiry alerts'),
            ),
          );
        }
      }
    }
  }

  void _showWebNotification(String title, String body) {
    if (html.Notification.supported && html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  }

  Future<void> _checkExpiringItems() async {
    if (_auth.currentUser == null) return;

    final snapshot = await _firestore
        .collection('pantry')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .where('monthKey', isEqualTo: selectedMonth)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['expiryDate'] != null) {
        final expiryDate = DateTime.parse(data['expiryDate']);
        if (expiryDate.difference(DateTime.now()).inDays <= 3) {
          _showWebNotification(
            'Item Expiring Soon',
            '${data['name']} will expire on ${DateFormat('MMM dd, yyyy').format(expiryDate)}',
          );
        }
      }
    }
  }

  Future<void> _addPantryItem() async {
    if (_auth.currentUser == null) return;

    final item = PantryItem(
      name: _nameController.text,
      quantity: double.parse(_quantityController.text),
      type: _selectedType,
      category: _selectedCategory,
      expiryDate: _selectedExpiryDate,
      unit: _selectedUnit,
      trackLowStock: _trackLowStock,
      lowStockThreshold: _trackLowStock
          ? double.parse(_lowStockThresholdController.text)
          : 1.0,
    );

    await _firestore.collection('pantry').add({
      ...item.toMap(),
      'userId': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (_selectedExpiryDate != null) {
      _showWebNotification(
        'Item Added with Expiry Date',
        '${_nameController.text} will expire on ${DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!)}',
      );
    }

    _resetForm();
  }

  void _resetForm() {
    _nameController.clear();
    _quantityController.clear();
    _lowStockThresholdController.clear();
    setState(() {
      _selectedType = ItemType.perishable;
      _selectedExpiryDate = null;
      _selectedUnit = 'units';
      _trackLowStock = false;
      _selectedCategory = ItemCategory.grainsPasta;
    });
  }

  Future<void> _deletePantryItem(String docId) async {
    await _firestore.collection('pantry').doc(docId).delete();
  }

  Future<void> _updateQuantity(String docId, double newQuantity) async {
    await _firestore.collection('pantry').doc(docId).update({
      'quantity': newQuantity,
    });

    // Check if item is low in stock
    final doc = await _firestore.collection('pantry').doc(docId).get();
    final data = doc.data();
    if (data != null && data['trackLowStock'] == true) {
      if (newQuantity <= data['lowStockThreshold']) {
        // Add to shopping list
        await _firestore.collection('shoppingList').add({
          'userId': _auth.currentUser!.uid,
          'name': data['name'],
          'purchased': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data['name']} is low in stock. Added to shopping list.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pantry Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('pantry')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('monthKey', isEqualTo: selectedMonth)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ));
            }

            final items = snapshot.data!.docs;
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.kitchen_outlined, size: 64, color: Colors.teal[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Your pantry is empty',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddItemDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Items'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group items by category
            Map<String, List<DocumentSnapshot>> groupedItems = {};
            for (var doc in items) {
              final data = doc.data() as Map<String, dynamic>;
              final category = data['category'].toString().split('.').last;
              if (!groupedItems.containsKey(category)) {
                groupedItems[category] = [];
              }
              groupedItems[category]!.add(doc);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final category = groupedItems.keys.elementAt(index);
                final categoryItems = groupedItems[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        getCategoryDisplayName(ItemCategory.values.firstWhere(
                          (e) => e.toString().split('.').last == category,
                        )),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoryItems.length,
                      itemBuilder: (context, itemIndex) {
                        final doc = categoryItems[itemIndex];
                        final data = doc.data() as Map<String, dynamic>;
                        final expiryDate = data['expiryDate'] != null
                            ? DateTime.parse(data['expiryDate'])
                            : null;
                        final isExpiringSoon = expiryDate != null &&
                            expiryDate.difference(DateTime.now()).inDays <= 3;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Dismissible(
                            key: Key(doc.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) =>
                                _deletePantryItem(doc.id),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: isExpiringSoon ? Colors.red[50] : Colors.white,
                                  child: ExpansionTile(
                                    onExpansionChanged: (expanded) {
                                      if (expanded) {
                                        _animationController.forward();
                                      } else {
                                        _animationController.reverse();
                                      }
                                    },
                                    title: Text(
                                      data['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isExpiringSoon ? Colors.red : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Quantity: ${data['quantity']} ${data['unit']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        if (expiryDate != null)
                                          Text(
                                            'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDate)}',
                                            style: TextStyle(
                                              color: isExpiringSoon ? Colors.red : Colors.grey[600],
                                              fontWeight: isExpiringSoon ? FontWeight.bold : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: Colors.red[400],
                                          onPressed: () => _updateQuantity(
                                            doc.id,
                                            (data['quantity'] as num).toDouble() - 1,
                                          ),
                                        ),
                                        Text(
                                          '${data['quantity']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          color: Colors.green[400],
                                          onPressed: () => _updateQuantity(
                                            doc.id,
                                            (data['quantity'] as num).toDouble() + 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      FadeTransition(
                                        opacity: _animation,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Type: ${data['type'].toString().split('.').last}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              if (data['trackLowStock'] == true)
                                                Text(
                                                  'Low Stock Alert: ${data['lowStockThreshold']} ${data['unit']}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    // Ensure initial unit is valid for initial category
    _selectedUnit = categoryUnits[_selectedCategory]![0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.teal[700]),
              const SizedBox(width: 8),
              const Text('Add Pantry Item'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.shopping_basket),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ItemCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: ItemCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(getCategoryDisplayName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                        // Reset unit to first available unit for the new category
                        _selectedUnit = categoryUnits[value]![0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  items: categoryUnits[_selectedCategory]!
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedUnit = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() => _selectedExpiryDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedExpiryDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Track Low Stock'),
                  value: _trackLowStock,
                  onChanged: (value) {
                    setState(() => _trackLowStock = value);
                  },
                  secondary: Icon(Icons.track_changes, color: Colors.teal[700]),
                ),
                if (_trackLowStock) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lowStockThresholdController,
                    decoration: InputDecoration(
                      labelText: 'Low Stock Threshold',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.warning),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                _addPantryItem();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }
}
