import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDiscountManagementScreen extends StatefulWidget {
  const AdminDiscountManagementScreen({super.key});

  @override
  State<AdminDiscountManagementScreen> createState() =>
      _AdminDiscountManagementScreenState();
}

class _AdminDiscountManagementScreenState
    extends State<AdminDiscountManagementScreen> {
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new discount offer.
  Future<void> _addDiscount() async {
    final String store = _storeController.text.trim();
    final String offer = _offerController.text.trim();
    if (store.isEmpty || offer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }
    try {
      await _firestore.collection('discounts').add({
        'store': store,
        'offer': offer,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _storeController.clear();
      _offerController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount added successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding discount: $e")),
      );
    }
  }

  /// Deletes a discount offer.
  Future<void> _deleteDiscount(String docId) async {
    try {
      await _firestore.collection('discounts').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount deleted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting discount: $e")),
      );
    }
  }

  /// Updates an existing discount offer.
  Future<void> _updateDiscount(
      String docId, String newStore, String newOffer) async {
    try {
      await _firestore.collection('discounts').doc(docId).update({
        'store': newStore,
        'offer': newOffer,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount updated.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating discount: $e")),
      );
    }
  }

  /// Shows an edit dialog for a discount offer.
  void _showEditDialog(String docId, String currentStore, String currentOffer) {
    final TextEditingController storeController =
        TextEditingController(text: currentStore);
    final TextEditingController offerController =
        TextEditingController(text: currentOffer);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Discount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: storeController,
              decoration: const InputDecoration(labelText: "Store"),
            ),
            TextField(
              controller: offerController,
              decoration: const InputDecoration(labelText: "Offer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStore = storeController.text.trim();
              final newOffer = offerController.text.trim();
              if (newStore.isNotEmpty && newOffer.isNotEmpty) {
                await _updateDiscount(docId, newStore, newOffer);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discount Management")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form to add a discount offer.
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: "Store",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _offerController,
              decoration: const InputDecoration(
                labelText: "Offer",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addDiscount,
              child: const Text("Add Discount"),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('discounts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("No discounts found."));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String store = data['store'] ?? 'Unknown Store';
                      final String offer = data['offer'] ?? 'No offer details';
                      return Card(
                        child: ListTile(
                          title: Text(store),
                          subtitle: Text(offer),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(
                                    docs[index].id, store, offer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteDiscount(docs[index].id),
                              ),
                            ],
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
