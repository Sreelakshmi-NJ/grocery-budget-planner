import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  State<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    try {
      await _firestore.collection('categories').add({
        'name': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
      
      _categoryController.clear();
      _descriptionController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  Future<void> _toggleCategoryStatus(String categoryId, bool currentStatus) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'isActive': !currentStatus,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating category: $e')),
      );
    }
  }

  Future<void> _editCategory(String categoryId, String name, String description) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'name': name.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating category: $e')),
      );
    }
  }

  void _showEditDialog(String categoryId, String currentName, String currentDescription) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController descController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _editCategory(categoryId, nameController.text, descController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: Colors.teal[700],
      ),
      body: Column(
        children: [
          // Add Category Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addCategory,
                      child: const Text('Add Category'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Category List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('categories').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs;
                
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final data = category.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['name'] as String? ?? '',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                        subtitle: Text(data['description'] as String? ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(
                                category.id,
                                data['name'] as String? ?? '',
                                data['description'] as String? ?? '',
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (value) => _toggleCategoryStatus(category.id, isActive),
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
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 