import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  /// Toggles a user's role between 'user' and 'admin'
  Future<void> _toggleUserRole(String uid, String currentRole) async {
    setState(() => _isLoading = true);
    try {
      String newRole = currentRole == 'admin' ? 'user' : 'admin';
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated role to $newRole')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Deletes a user from the system
  Future<void> _deleteUser(String uid, String email) async {
    setState(() => _isLoading = true);
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Delete user document
      await _firestore.collection('users').doc(uid).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.teal[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin-home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;
                    final name = data['name'] ?? 'Unnamed User';
                    final email = data['email'] ?? 'No Email';
                    final role = data['role'] ?? 'user';
                    final phone = data['phone'] ?? 'No Phone';
                    final profileImage = data['profileImage'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                          child: profileImage == null
                              ? Text(name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.teal))
                              : null,
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Text('Phone: $phone'),
                            Text('Role: ${role[0].toUpperCase()}${role.substring(1)}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                color: role == 'admin' ? Colors.teal : Colors.grey,
                              ),
                              onPressed: () => _toggleUserRole(uid, role),
                              tooltip: 'Toggle admin status',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(uid, email),
                              tooltip: 'Delete user',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
