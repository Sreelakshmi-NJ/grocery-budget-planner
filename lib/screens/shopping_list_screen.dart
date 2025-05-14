import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController itemController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final String itemName = itemController.text.trim();
    if (itemName.isEmpty) return;

    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items.')),
      );
      return;
    }

    try {
      await _firestore.collection('shoppingList').add({
        'userId': user.uid,
        'name': itemName,
        'purchased': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      itemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $itemName to your list'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error adding item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _togglePurchased(String docId, bool currentValue) async {
    try {
      await _firestore.collection('shoppingList').doc(docId).update({
        'purchased': !currentValue,
      });
    } catch (e) {
      debugPrint('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating item: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeItem(String docId, String itemName) async {
    try {
      await _firestore.collection('shoppingList').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $itemName from your list'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearShoppingList() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('shoppingList')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        await _firestore.collection('shoppingList').doc(doc.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shopping list cleared'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error clearing shopping list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing shopping list: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shopping List'),
          backgroundColor: Colors.teal[700],
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.teal[300]),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view your shopping list',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Clear All',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear Shopping List'),
                content: const Text('Are you sure you want to clear your entire shopping list?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _clearShoppingList();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: itemController,
                      decoration: InputDecoration(
                        hintText: 'Add item to your list',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.shopping_cart_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: Colors.teal,
                          onPressed: _addItem,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('shoppingList')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: 64,
                            color: Colors.teal[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your shopping list is empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items using the field above',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String itemName = data['name'] ?? '';
                      final bool purchased = data['purchased'] ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: Key(doc.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) => _removeItem(doc.id, itemName),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: purchased,
                                onChanged: (value) => _togglePurchased(doc.id, purchased),
                                activeColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text(
                                itemName,
                                style: TextStyle(
                                  decoration: purchased ? TextDecoration.lineThrough : null,
                                  color: purchased ? Colors.grey : Colors.black,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!purchased)
                                    IconButton(
                                      icon: const Icon(Icons.shopping_cart_checkout),
                                      onPressed: () => _togglePurchased(doc.id, purchased),
                                      color: Colors.teal,
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeItem(doc.id, itemName),
                                    color: Colors.red[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
